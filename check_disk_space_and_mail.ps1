
# from http://sharepointnomad.wordpress.com/2010/10/29/powershell-script-to-monitor-server-disk-space-and-send-out-email-alerts/
# 5 Dec 2011
# This script performs the following actions:
#  1) Read a list of servers
#
#  2) For each server on the list, get disk drive information - drive letter, drive size, free space, percent free
#
#  3) Email the report to users specified by the $users variable
#

$users = "user1 @ domain.com", "user2 @ domain.com " , "user3 @ domain.com" 
$server = "SMTP server name or IP address"
$port = 25
$list = $args[0]
$output = $args[1]
$computers = get-content $list

echo "SharePoint Storage Report" > $output
echo " " >> $output
echo "Note: Free space below 30% is labeled with *** " >> $output
echo " " >> $output
echo " " >> $output
echo "ServerName    Drive Letter Drive Size Free Space Percent Free" >> $output
echo "----------    ------------ ---------- ---------- ------------" >> $output
foreach ($line in $computers)
{
 $computer = $line 
  
 $drives = Get-WmiObject -ComputerName $computer Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
 foreach($drive in $drives)
 {
 
 $id = $drive.DeviceID
 $size = [math]::round($drive.Size / 1073741824, 2)
 $free = [math]::round($drive.FreeSpace  / 1073741824, 2)
 $pct = [math]::round($free / $size, 2) * 100
  
 if ($pct -lt 30) { $pct = $pct.ToString() + "% *** " }
 
 else {  $pct = $pct.ToString() + " %" }
 
echo "$computer   $id  $size  $free  $pct"  >> $output
 
$pct = 0 
 
 }
 
}
foreach ($user in $users)
{
 
$to      = $user
 
$from    = "<a href="mailto:diskspacemonitor@domain.com">diskspacemonitor@domain.com</a>"
 
$subject = "Connect Storage Report"
 
foreach ($line in Get-Content $output)
 
{
 
$body += “$line `n”
 
}
 
# Create mail message
$message = New-Object system.net.mail.MailMessage $from, $to, $subject, $body
 
#Create SMTP client
$client = New-Object system.Net.Mail.SmtpClient $server, $port

# Credentials are necessary if the server requires the client # to authenticate before it will send e-mail on the client's behalf. 
$client.Credentials = [system.Net.CredentialCache]::DefaultNetworkCredentials
# Try to send the message
 
try {      
$client.Send($message)      
"Message sent successfully"
# reset variables
$body = ""
}
 
# Catch an error
catch {
"Exception caught in CreateTestMessage1(): "
}
 
}
 
# End of Script