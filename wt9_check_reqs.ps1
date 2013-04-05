# $Id: wt9_check_reqs.ps1,v 1.4 2012/01/02 15:25:44 powem Exp $
# Last Modified: $Date: 2012/01/02 15:25:44 $
# Michael Powe, WebTrends EPS
#


#region Global definitions

# local user path, by default desktop of the user running the script
# used to write log of all installed roles/services
$fpath = "$env:USERPROFILE\Desktop\roles_installed.txt"
# the current user (who opened the PS command shell)
$currentRole = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# officially required, per WebTrends documentation
# These are the role/service DisplayNames
$required = ("Application Server", ".NET Framework 3.5.1", "Web Server (IIS) Support",
"Windows Process Activation Service Support",  "HTTP Activation", 
"Message Queuing Activation", "Web Server (IIS)", "Web Server", "Common HTTP Features", 
"Static Content", "Default Document", "Directory Browsing", "HTTP Errors", 
"HTTP Redirection", "Application Development", "ASP.NET", ".NET Extensibility", 
"ISAPI Extensions", "ISAPI Filters", "Health and Diagnostics", "HTTP Logging", 
"Logging Tools", "Request Monitor", "Tracing", "Security", "Basic Authentication", 
"Windows Authentication", "Digest Authentication", "Client Certificate Mapping Authentication",
"IIS Client Certificate Mapping Authentication", "URL Authorization", 
"Request Filtering", "IP and Domain Restrictions", "Performance",
"Static Content Compression", "Dynamic Content Compression", "Management Tools", 
"IIS Management Console", "IIS Management Scripts and Tools", "Management Service", 
"IIS 6 Management Compatibility", "IIS 6 Metabase Compatibility", "IIS 6 WMI Compatibility", 
"IIS 6 Scripting Tools", "IIS 6 Management Console"
 )

# Used for missing requirements, if any
$notInstalled = @()

# Used for roles/services installed but not required, if any
$not_required = @()

#endregion

#region Boolean test functions

function Test-OperatingSystem{
<#
 .Synopsis
  Returns TRUE if the operating system is identified as R2, FALSE otherwise
#>
	if(((gwmi Win32_OperatingSystem).Caption).Contains("R2")){
		$true
	} else {
		$false
	}
}

function Test-Admin{
<#
 .Synopsis
  Tests if a given user in the Administrator role
  
 .Description
  Returns TRUE of the user is in the Administrator role, FALSE otherwise. The
  default is to capture the role of the user executing the function or script.
  
 .Parameter CurrentRole
  An object that describes the user role.  This object is of the Security.Principal.WindowsPrincipal class.
#>
	param($currentRole = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())))
	if ($currentRole.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
		$true
	} else {
		$false
	}
}

function Test-ServerManager{
<#
 .Synopsis
  Return TRUE if the ServerManager module is available, FALSE otherwise.
  
#>
	if(Test-wtModule -Name "ServerManager"){
		$true
	} else {
		$false
	}
}

function Test-OfficeVersion {

	param( [switch] $boolean = $false)
	$version = 0.0
	$installed = $false
	
	
		
}

function Test-wtModule{
    param(
          [string]$modulename
         )
    if(Get-Module -ListAvailable | Where-Object { $_.name -eq $modulename }){
			$true
	} 
	else { $false }
}

#endregion

#region Getters

function Get-OperatingSystem{
<#
 .Synopsis
  Determines whether the operating system meets the minimum requirements
  for a WebTrends installation and exits if not.
  
 .Description
  The OS must be Windows 2008 R2, minimum.  The function checks for the R2
  in the OS description using Test-OperatingSystem and exits if it's not there.
#>
	if (Test-OperatingSystem){
		Write-Host ("`n`tOS: ", (gwmi Win32_OperatingSystem).Caption)
		Write-Host "`tMinimum Operating System requirements are met."
	} else {
		Write-Host "`tMinimum Operating System requirements not met."
		Write-Host ("`t",(gwmi Win32_OperatingSystem).Caption)
		Write-Host "`tExiting now."
		exit
	}
}



function Get-ServerManager {

	# Test if Server Manager module is available and loaded, exit if not
	if (Test-ServerManager){
		Write-Host "`tServer Manager module is available. Continuing..."
		Write-Host "`n"
	} else {
		throw [System.ArgumentNullException] "The server manager module is not available"
		exit
	}
}

function Get-UserRole {
<#
 .Synopsis
  Determines if the current user is in the Administrator group and returns a list
  of groups if not.
  
 .Description
  This function uses Test-Admin to verify that the current user is an Administrator
  on this system.  If the user is not an admin, it writes out a list of groups that
  the current user is a member of, for reference.
#>
	$user = $currentRole.Identity.Name
	
	if (Test-Admin){
		Write-Host ("`t",$user, " is an administrator. Continuing...")
		Write-Host "`n"
	} else {
		Write-Host "`tThis script must be run as administrator."
		Write-Host ($user, "is not an administrator on this system.")
		Write-Host ($user, "is in the following groups on this system.")
		Write-Host "-----"
		([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups | `
		?{ $_.Translate([System.Security.Principal.NTAccount]).ToString() -match "BUILTIN"} | `
		%{$_.Translate([System.Security.Principal.NTAccount])}
		Write-Host "-----"
		([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups | `
		?{ $_.Translate([System.Security.Principal.NTAccount]).ToString() -match "Domain"} | `
		%{$_.Translate([System.Security.Principal.NTAccount])}
		Write-Host "-----"
		Write-Host "`tExiting now."
		exit
	}
}

function Get-InstalledFeatures{
<#
 .Synopsis
  Collects a complete list of the currently installed roles and role services
  
 .Description
  Returns a hash consisting of the role Name as the key and the role DisplayName
  as the value, for all Roles and Role Services which are installed.
#>
	$tinst = @{}
	Get-WindowsFeature | ?{$_.Installed -eq $true} | %{$tinst[$_.Name] = $_.DisplayName}
	return $tinst
}

function Get-OfficeVersion{
	$version = "0000"
	$location = "HKCU:\Software\Microsoft\Office"
	if (-not(Test-Path -Path $location )){
		return $version
	} else {
		if (Test-Path -Path ($location+"\14.0")){
			$version = "2010"
		} elseif(Test-Path -Path ($location+"\12.0")) {
			$version = "2007"
		} elseif(Test-Path -Path ($location+"\11.0")){
			$version = "2003"
		}
	}
	return $version
}


#endregion

#region Setters

function Write-InstalledFeatures{
<#
 .Synopsis
  Writes out the set of installed features to a text file.
  
 .Description
  Takes the hash containing the features and a path, sorts the features based on 
  the keys and writes out the sorted list to a file.  By default, takes the 
  hash and the path set globally in the script.
  
 .Parameter Features
  The hash containing the server roles and role display names.
  
 .Parameter Path
  The path to which to write out the file.  This is done with Out-File, so it
  will always overwrite the previous file, if one exists.
#>
	param(
          [parameter(Mandatory=$true)]
          [hashtable]
          $features = $installed, 
          [parameter(Mandatory=$true)]
          [string]
          $path = $fpath
         )
	
	$features.getEnumerator() | Sort-Object -Property Name | out-File -FilePath $path

}

function Confirm-Features{
<#
 .Synopsis
  Compares a list of installed roles and role services to those required for 
  the installation of WebTrends.
  
 .Description
  Loops through the array of requirements and records those which are not found
  in the installed list.  
  
 .Parameter Current
  A hashtable that consists of the Feature name as the key and the Feature displayname
  as the value.
  
 .Parameter Requirements
  An array consisting of the Feature displaynames that must be installed for the
  WebTrends installation to proceed.
  
#>
	param(
            [parameter(Mandatory=$true)]
            [array]
            $current = $installed,
            [parameter(Mandatory=$true)]
            [array]
            $requirements = $required
          )
	
	$notInstalled = @()
	
	foreach ($r in $requirements){
		if (-not($current.Values -contains $r)){
			$notInstalled += $r
		}
	}
	
	return $notInstalled
}



#endregion

# Must be an R2 operating system

Get-OperatingSystem

# Must be run as administrator

Get-UserRole

# Must have the Server Manager module

Get-ServerManager

# ----------------- Basic requirements to run script are met if
# ----------------- We go beyond this point -------------------

# ----------------- Collect and check installed roles/services -------------------
# ----------------- against requirements -----------------------------------------
#
# collect all the installed roles/services
$installed = Get-InstalledFeatures

Set-InstalledFeatures($installed, $fpath)



# any role or service installed but not in the requirements list
foreach ($i in $installed.Values){
	if (-not($required -contains $i)){
			$not_required += $i
	}
}

#
# ------------------------------ report the results -------------------------------
# 
if( $notInstalled.length -gt 0){
	Write-Host "----------------------------------------------------------------"
	Write-Host "The following required items are not installed.`n"
	Write-Host ([string]::Join("`n",$notInstalled))
	Write-Host "`n"
	Write-Host "These items must be installed before WebTrends can be installed."
	Write-Host "----------------------------------------------------------------"
} else {
	Write-Host "--------------------------------------------------------------------------"
	Write-Host "`tAll WebTrends-specific roles and features are installed."
}

if ($not_required.length -gt 0){
	Write-Host "--------------------------------------------------------------------------"
	Write-Host "The following items are installed but are not required by WebTrends.`n"
	Write-Host ([string]::Join("`n",$not_required))
	Write-Host "`n"
}
Write-Host "-------------------------------------------------------------------------"
Write-Host "`tFinished."
Write-Host "-------------------------------------------------------------------------"
# --------------------------- end ---------------------------- #