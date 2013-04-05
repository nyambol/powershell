####################################################################################
# Name: CheckUserRightAssignments.ps1
# Version: 1.0
# Author: Bart Tukker
# Date: 06-12-2010
#################################################################################
Clear-Host
# declareer variabelen
$computername= $env:COMPUTERNAME
$tempdir = "c:\temp"
$file = "$tempdir\secdump.txt"
$fout = @()
$LocalArray = @()
$PermitArray = @()

# Voer Secedit uit voor exporteren van local policy inclusief userright assignments
$p = [diagnostics.process]::Start("secedit.exe", "/export /cfg $file")
$p.WaitForExit()
$inhoud = get-content $file

#Userright to check
$userright = "SeNetworkPrivilege"
#SeBatchLogonRight,Logon_as_a_batch_job
#SeChangeNotifyPrivilege,Bypass_Traverse_Checking
#SeImpersonatePrivilege,Impersonate_a_client_after_authentication
#SeIncreaseQuotaPrivilege,Adjust_memory_quotas_for_a_process
#SeInteractiveLogonRight,Allow_log_on_locally
#SeNetworkPrivilege,Access_this_computer_from_the_network
#SeServiceLogonRight,Log_on_as_a_service
#SeTcbPrivilege,Act_as_part_of_the_operating_system


# start check of local userrights
foreach ($line in $inhoud) {
	if ($line -like "$userright*") {
		$SIDstring = ($line -split {$_ -eq "=" -or $_ -eq "," -or $_ -eq " " -or $_ -eq "*"}|where-object {$_ -notlike "Se*" -and $_ -notlike ""})
		$i = 0

		while ($i -le $SIDstring.length -and $SIDstring[$i] -notlike $null) {
			if ($SIDstring[$i] -notlike "S-*" ){
			$LocalArray += $SIDstring[$i]
			} else {
				$SID = New-Object System.Security.Principal.SecurityIdentifier($SIDstring[$i])
			# If SID is not from domain and not local, it can't be resolved; display the SID in the list
				if (($SID.Value -notlike 'S-1-5-21-2000*') -and ($SID.Value -notlike 'S-1-5-32-*')) {
					$LocalArray += $SID.Value
				} else {
					$User = $SID.Translate([System.Security.Principal.NTAccount])
					$LocalArray += $User.Value
				}
			}
			$i++
		}
	}
}


#Define DEFAULT permitted users of specified userright $PermitArray =@()

If ($userright -eq 'SeAssignPrimaryTokenPrivilege'){$PermitArray = "NT AUTHORITY\LOCAL SERVICE", "NT AUTHORITY\NETWORK SERVICE"}
If ($userright -eq 'SeBatchLogonRight'){$PermitArray = "SUPPORT_388945a0", "NT AUTHORITY\LOCAL SERVICE"}
If ($userright -eq 'SeChangeNotifyPrivilege'){$PermitArray = "BUILTIN\Administrators", "BUILTIN\Backup Operators", "BUILTIN\Power Users", "BUILTIN\Users", "Everyone"}
If ($userright -eq 'SeDenyInteractiveLogonRight'){$PermitArray = "Guests" }
If ($userright -eq 'SeDenyRemoteInteractiveLogonRight'){$PermitArray = "Guests"}
If ($userright -eq 'SeImpersonatePrivilege'){$PermitArray = "BUILTIN\Administrators", "SERVICE"}
If ($userright -eq 'SeIncreaseQuotaPrivilege'){$PermitArray = "BUILTIN\Administrators" } #, "NT AUTHORITY\LOCAL SERVICE", "NT AUTHORITY\NETWORK SERVICE" }
If ($userright -eq 'SeInteractiveLogonRight'){$PermitArray = "BUILTIN\Administrators", "BUILTIN\Backup Operators", "BUILTIN\Power Users"}
If (($userright -eq 'SeNetworkPrivilege') -or ($userright -eq 'SeNetworkLogonRight')) {$PermitArray = "BUILTIN\Administrators", "BUILTIN\Backup Operators", "BUILTIN\Power Users", "BUILTIN\Users", "Everyone"}
If ($userright -eq 'SeServiceLogonRight'){$PermitArray = "NT AUTHORITY\NETWORK SERVICE"}
If ($userright -eq 'SeTcbPrivilege'){$PermitArray = "" }

#SQL
If (Get-Service -Name 'SQLServer*') {
If ($userright -eq 'SeChangeNotifyPrivilege') {$PermitArray += "svcSQL"}
If ($userright -eq 'SeImpersonatePrivilege') {$PermitArray += "svcSQL"}
If ($userright -eq 'SeIncreaseQuotaPrivilege') {$PermitArray += "svcSQL"}
If ($userright -eq 'SeServiceLogonRight') {$PermitArray += "svcSQL"}

}

#IIS
#IIS6: http://support.microsoft.com/?id=812614
#IIS7: http://support.microsoft.com/kb/981949
If (Get-Service -Name 'W3SVC*'){
	If ($userright -eq 'SeBatchLogonRight') {$PermitArray += "IIS_WPG", "IUSR_$computername", "IWAM_$computername"}
	If ($userright -eq 'SeImpersonatePrivilege') {$PermitArray += "APSNET", "IIS_WPG"}
	If ($userright -eq 'SeIncreaseQuotaPrivilege') {$PermitArray += "IWAM_$computername" }
	If ($userright -eq 'SeInteractiveLogonRight') {$PermitArray += "ASPNET"}
	If (($userright -eq 'SeNetworkPrivilege') -or ($userright -eq 'SeNetworkLogonRight')) {$PermitArray += "ASPNET", "IUSR_$computername", "IWAM_$computername" }
	If ($userright -eq 'SeServiceLogonRight') {$PermitArray += "ASPNET" }
}

# Compare PermitArray met LocalArray
$d = Compare-Object -ReferenceObject $PermitArray -DifferenceObject $LocalArray
$d | ForEach-Object { 
		If ($_.SideIndicator -match '=>') {
			$fout += $_.InputObject +'; '
			#$_.InputObject
		}
	}

if ($fout -ne $null){
	Write-Host 'FAULTY: more groups/account present than expected:'
	Write-Host $fout
	exit 0
} else {
	Write-Host 'GOOD: No more groups/account present than expected!'
	#Write-Host $d
	exit 1
} 