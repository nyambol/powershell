# from http://www.youdidwhatwithtsql.com/check-disk-space-with-powershell-2/195
# 5 Dec 2011
# $Id$
# Issue warning if % free disk space is less
$percentWarning = 15;

$userdir = "$Env:USERPROFILE\wt_user.txt"
$passdir = "$Env:USERPROFILE\wt_pass.txt"

# Get server list
$servers = Get-Content "$Env:USERPROFILE\serverlist.txt";
$datetime = Get-Date -Format "yyyyMMddHHmmss";

# Get credentials

if ((Test-Path $passdir) -ne $true){
	$cred = Get-Credential
	$cred.Password | ConvertFrom-SecureString | Set-Content $passdir
	$cred.UserName | Set-Content $userdir
} else {
	$wt_pass = Get-Content $passdir
	$secpasswd = ConvertTo-SecureString $wt_pass -AsPlainText -Force
	$wt_user = Get-Content $userdir
	$cred = New-Object System.Management.Automation.PSCredential ($wt_user, $wt_pass)
}
# Add headers to log file
Add-Content "$Env:USERPROFILE\server_disks_$datetime.txt" "server,deviceID,size,freespace,percentFree";

foreach($server in $servers)
{
	# Get fixed drive info
	$disks = Get-WmiObject -ComputerName $server -Credential $cred -Class Win32_LogicalDisk -Filter "DriveType = 3";
	foreach($disk in $disks)
	{
		$deviceID = $disk.DeviceID;
		[float]$size = $disk.Size;
		[float]$freespace = $disk.FreeSpace;
		$percentFree = [Math]::Round(($freespace / $size) * 100, 2);
		$sizeGB = [Math]::Round($size / 1073741824, 2);
		$freeSpaceGB = [Math]::Round($freespace / 1073741824, 2);
		$colour = "Green";
		if($percentFree -lt $percentWarning)
		{
			$colour = "Red";
		}
		Write-Host -ForegroundColor $colour "$server $deviceID percentage free space = $percentFree";
		Add-Content "$Env:USERPROFILE\server disks $datetime.txt" "$server,$deviceID,$sizeGB,$freeSpaceGB,$percentFree";
	}
}
