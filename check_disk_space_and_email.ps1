#########################################################
#
# Disk space monitoring and reporting script
#
# $Id: check_disk_space_and_email.ps1,v 1.2 2011/12/12 15:39:23 powem Exp $
# Originally from 
# http://www.simple-talk.com/sysadmin/powershell/disk-space-monitoring-and-early-warning-with-powershell/
# Modified by Michael Powe, WebTrends EPS
# Last Modified: $Date: 2011/12/12 15:39:23 $
#########################################################

# timestamp the report
$day = Get-Date -Format D
$time = Get-Date -Format T

# if $true, append new report to bottom of existing report
# otherwise, overwrite
$accum = $false
$report = "$Env:USERPROFILE\Desktop\diskusage.html"

# List of users to email your report to (separate by comma)
$users = "toaddress@yourdomain.com" 
$fromemail = "fromaddress@yourdomain.com"
#enter your own SMTP server DNS name / IP address here
$server = "yourmailserver.yourdomain.com" 

$list = $args[0] #This accepts the argument you add to your scheduled task for the list of servers. i.e. list.txt

if ($list){
	$computers = get-content $list #grab the names of the servers/computers to check from the list.txt file.
} else {
	$computers = "."
}

# Set free disk space threshold below in percent (default at 45%)
[decimal]$thresholdspace = 45

# assemble together all of the free disk space data from the list of servers 
# and only include it if the percentage free is below the threshold we set above.

$tableFragment= Get-WMIObject  -ComputerName $computers Win32_LogicalDisk `
| select __SERVER, DriveType, VolumeName, Name, @{n='Size (Gb)' ;e={"{0:n2}" -f ($_.size/1gb)}},@{n='FreeSpace (Gb)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='PercentFree';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} `
| Where-Object {$_.DriveType -eq 3 -and [decimal]$_.PercentFree -lt [decimal]$thresholdspace} `
| ConvertTo-HTML -fragment

# assemble the HTML for our body of the report.

$HTMLmessage = @"
<style type=""text/css"">body{font: .8em ""Lucida Grande"", Tahoma, Arial, Helvetica, sans-serif; background-color:white}
ol{margin:0;padding: 0 1.5em;}
table{color:#660000;background:#C0C0C0;border-collapse:collapse;width:647px;border:5px solid #900;}
thead{}
thead th{padding:1em1em 1em .5em;border-bottom:1px dotted #FFF;font-size:120%;text-align:left;}
thead tr{}
td{padding:.5em 1em;}
tfoot{}
tfoot td{padding-bottom:1.5em;}
tfoot tr{}
#middle{background-color:#900;}
</style>
<body>
<h2>Disk Space Storage Report</h2>
<p>
$day<br/>
$time<br/>
</p>
<p>
The drive(s) listed below have less than $thresholdspace % free space. Drives above this threshold will not be listed.
</p>
$tableFragment
</body>
"@

# Set up a regex search and match to look for any <td> tags in our body. These would only be present if the script above found disks below the threshold of free space.
# We use this regex matching method to determine whether or not we should send the email and report.

$regexsubject = $HTMLmessage
$regex = [regex] '(?im)<td>'

# if there was any row at all, send the email
if ($regex.IsMatch($regexsubject)) {
	# send-mailmessage -from $fromemail -to $users -subject "Disk Space Monitoring Report" -BodyAsHTML -body $HTMLmessage -priority High -smtpServer $server
	if ($accum){
		$HTMLmessage | Add-Content $report
	} else {
		$HTMLmessage | Set-Content $report
	}
}

# End of Script