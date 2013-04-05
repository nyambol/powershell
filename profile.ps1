
# $Id: profile.ps1,v 1.10 2012/09/18 21:12:43 powem Exp $
# Last Modified: $Date: 2012/09/18 21:12:43 $
# 31 January 2013 13:22
# Michael Powe

if ($PSVersionTable.PSVersion.Major -eq 2){
    Write-Host "Importing modules for version 2";
    Import-Module Pscx
    Import-Module WebTrends-Module.psm1
} else {
    Write-Host "Autoloading modules for version 3";
}

#region PSDrives

Write-Host("Creating custom PSDrives:")

if (Test-Path "c:\Users\powem\Documents\clients\accounts\zinio"){
	New-PSDrive -Name zinio -Root c:\Users\powem\Documents\clients\accounts\zinio `
				-PSProvider filesystem -Description "Zinio root folder"
}
if (Test-Path "c:\Users\powem\Documents\clients\accounts"){
	New-PSDrive -Name accounts -Root c:\Users\powem\Documents\clients\accounts `
				-PSProvider filesystem -Description "Webtrends accounts"
}
if (Test-Path "c:\Users\powem\Documents\clients"){
	New-PSDrive -Name clients -Root c:\Users\powem\Documents\clients `
				-PSProvider filesystem -Description "Clients root folder"
}
if (Test-Path c:\logs){
	New-PSDrive -Name logs -Root c:\logs -PSProvider filesystem -Description "Log files folder"
}
if (Test-Path c:\src){
	New-PSDrive -Name src  -Root c:\src -PSProvider  filesystem -Description "Source code folder"
}

if (Test-Path C:\tools) {
    New-PSDrive -Name tools -Root C:\tools -PSProvider FileSystem -Description "Programming tools"
}

#endregion

#region Environment

Add-Type -AssemblyName System.Web

$Env:sdcfields = "date time c-ip cs-username cs-host cs-method cs-uri-stem cs-uri-query sc-status sc-bytes cs-version cs(User-Agent) cs(Cookie) cs(Referer) dcs-id"
$Env:sdcregex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<host>[^ ]+) [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"

# Location for PowerShell scripts and modules
$psScripts = "c:\powershell";
$psUserHome = "c:\Users\powem\Documents\WindowsPowerShell";
$psUserModule = "C:\Users\powem\Documents\WindowsPowerShell\Modules";

$wtPsd1 = "WebTrends-Module.psd1";
$wtPsm1 = "WebTrends-Module.psm1";
$prof = "profile.ps1";

$wtPsd1Dev  = Join-Path $psScripts $wtPsd1;
$wtPsd1Prod = Join-Path $psUserModule $wtPsd1;

$wtPsm1Dev  = Join-Path $psScripts $wtPsm1;
$wtPsm1Prod = Join-Path $psUserModule $wtPsm1;

$profDev  = Join-Path $psScripts $prof;
$profProd = Join-Path $psUserHome $prof;

#endregion

#region Display Settings

(Get-Host).PrivateData.ErrorForegroundColor = 'yellow';
(Get-Host).PrivateData.ErrorBackgroundColor = 'blue';

$ErrorView = 'CategoryView';

# Note:  to rename files in a directory:
# ls | Rename-Item -NewName {$_.Name + ".log"}; 	--> adds '.log' extension to each file

function prompt {
	$nextId = (get-history -count 1).Id + 1;
	$currPath = (Get-Location).Path
	$promptText = "{0}`n{{{1}}} [{2}] -->" -f $currPath,$env:USERNAME,$nextId
	$wi = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$wp = new-object 'System.Security.Principal.WindowsPrincipal' $wi
	$psversion = "PS-V2";
	if($PSVersionTable.PSVersion.Major -eq 3){
		$psversion = "PS-V3";
	}
	if ( $wp.IsInRole('Administrators'))
	{
		$color = "White"
		$title = '**ADMIN** - ' + $psversion + " - " + (get-location).Path;
	}
	else
	{
		$color = "Green"
		$title = 'Non-Admin - ' + $psversion + " - " + (get-location).Path;
	}
	write-host $promptText -NoNewLine -ForegroundColor $color
	$Host.UI.RawUI.WindowTitle = $title;
	return " "
}

#endregion


#region Custom Functions

function Format-Case{
<#
.Synopsis
 Format a given string into upper, lower, or proper case.

.Description
 Specify a string and optionally, -U for upper case or -L for lower case.  Default behavior is to proper case the string.

.Parameter Text
 The string to be modified.

.Parameter L
 Optional switch to lower-case the string.

.Parameter U
 Optional switch to upper-case the string.

#>

    param(
        [parameter(Mandatory=$true)] 
        [string]$Text,
        [parameter(Mandatory=$false)]
        [switch]$L,
        [parameter(Mandatory=$false)]
        [switch]$U
    )
    
    begin{

        [string]$processed = "";
    }

    process{
            if($L) 
            { 
                $processed = (Get-Culture).TextInfo.ToLower($Text);
            }
            elseif($U) 
            {
                $processed = (Get-Culture).TextInfo.ToUpper($Text);
            }
            else 
            {
                $processed = (Get-Culture).TextInfo.ToTitleCase((Get-Culture).TextInfo.ToLower($Text));
            }
    }
    end{
    
        return $processed;
    }
}

function Verify-MD5{
<#
.Synopsis 
 Find and optional verify the MD5 value for a file.

.Description
 Run the MD5 verification tool to find the value for a given file.  Optionally, pass in the known or assumed value for 
 the file and determine if the two values match. If the MD5 string is not passed into the script, the script will just 
 return the file's value.  See notes for important caveats.

.Parameter Target
 The full path to the file to be checked.

.Parameter md5
 The MD5 string for the target file.  If this optional value is supplied, the script will verify the file.  

.Notes
 The script uses the free utility provided by Microsoft to find the MD5 value of the file.
 The FCIV tool provided by Microsoft outputs in this format:
 //
 // File Checksum Integrity Verifier version 2.05.
 //
 78acefe909b570dc0d2e59484f126056 c:\users\powem\desktop\mysql-installer-community-5.6.10.1.msi
 If another program is substituted, and the data output is not in the format shown above, use the $all option to have the script
 write the entire output string to the console.
#>

    param(
        [parameter(Mandatory=$true)]
		      [alias("t")]
		      [string]$target,
        [parameter(Mandatory=$false)]
              [alias("m")]
              [string]$md5,
        [parameter(Mandatory=$false)]
              [alias("p")]
              [string]$program="C:\fciv\fciv.exe",
        [parameter(Mandatory=$false)]
              [alias("a")]
              [switch]$all

    )

    begin {
        $pass_color = "green";
        $fail_color = "red";
        $md_color   = "yellow";

        if(-not (Test-Path -Path $program)) {
            throw [System.IO.FileNotFoundException] "MD5 verification tool not found.  Check your path.";
        }

        if(-not (Test-Path -Path $target)) {
            throw [System.IO.FileNotFoundException] "File to be verified not found.  Check your path.";
        }
    }
    process {
        $value = (Invoke-Expression -Command ($program + " " + $target));

        if($all){
            $md = $value;
        } else {
            $md = $value | ?{-not($_.StartsWith("/"))} | %{$_.Split(" ")[0]};
        }
    }

    end {
        if($md5){
            if($md -eq $md5){
                Write-Host -ForegroundColor $pass_color ("MD5 verification passed.")
                Write-Host -ForegroundColor $md_color ("`n`t{0} matches {1}" -f $md, $md5);
            } elseif ($md -ne $md5){
                Write-Host -ForegroundColor $fail_color ("MD5 verification FAILED.");
                Write-Host -ForegroundColor $md_color ("`n`t{0} does not match {1}" -f $md, $md5);
            }
        } else {
            Write-Host $md;
        }
    }
}


function Get-Noop {
<#
.Synopsis
 This is the noop function.
#>

	Write-Host "This is a no-op function."
	
}

function ProcessFile
{
<#
 .Synopsis
  Processes files from a pipeline and returns values found via
  regular expression.

 .Description
  This function was written for me in response to a question in 
  StackOverflow.
#>


   param(
      [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
      [System.IO.FileInfo] $File,

      [Parameter(Mandatory = $true)]
      [string] $Pattern,

      [Parameter(Mandatory = $true)]
      [int] $Group
   )

   begin
   {
      $regex = new-object Regex @($pattern, 'Compiled')
      $set = new-object 'System.Collections.Generic.SortedDictionary[string, int]'
      $totalCount = 0
   }

   process
   {
      try
      {
        $reader = new-object IO.StreamReader $_.FullName

        while( ($line = $reader.ReadLine()) -ne $null)
        {
           $m = $regex.Match($line)
           if($m.Success)
           {
              $set[$m.Groups[$group].Value] = 1      
              $totalCount++
           }
        }
      }
      finally
      {
         $reader.Close()
      }
   }

   end
   {
      new-object psobject -prop @{TotalCount = $totalCount; Unique = ([string[]]$set.Keys)}
   }
}


function Copy-WtModule{

<#
 .Synopsis
  Copy the Webtrends-Module to the module directory if it has been updated.

 .Description
  A shortcut to copy the modified module file into place.  It checks to see
  if the module file in place is older than the one in the source directory.
  After the copy, it unloads the module and reloads it.

#>


    if ((Get-Item $wtPsd1).LastWriteTime -gt (Get-Item $wtPsd1Prod).LastWriteTime){
        Copy-Item -Path $wtPsd1 -Destination "c:\Users\powem\Documents\WindowsPowerShell\Modules\WebTrends-Module\";
        Write-Host "New manifest file copied over.";
    }

	if ((Get-Item "c:\powershell\WebTrends-Module.psm1").LastWriteTime -gt (Get-Item "c:\Users\powem\Documents\WindowsPowerShell\Modules\WebTrends-Module\WebTrends-Module.psm1").LastWriteTime){
		Copy-Item -Path "c:\powershell\WebTrends-Module.psm1" -Destination "c:\Users\powem\Documents\WindowsPowerShell\Modules\WebTrends-Module\";
		Write-Host "New Webtrends module file copied over."
		Write-Host "Removing WebTrends-Module...";
		Remove-Module WebTrends-Module
		Write-Host "Done."
		Write-Host "Importing WebTrends-Module";
		Import-Module WebTrends-Module.psm1
		Write-Host "WebTrends-Module loaded";
	} else {
		Write-Host "Webtrends module is current."
	}
}


function Show-ErrorDetail{
	param(
		$errorRecord = $Error[0]
	)
	Write-Host ("Exception message is: `n {0}`n" -f $errorRecord.Exception);
	Write-Host("Invocation information is: `n");
	$errorRecord.InvocationInfo | Format-List *;
}




#endregion

#region History Archiving and Loading

# save last 100 history items on exit
$historyPath = Join-Path (split-path $profile) history.clixml

# This is from Nivot Ink's (@oising) blog post http://www.nivot.org/2009/08/15/PowerShell20PersistingCommandHistory.aspx
# hook powershell's exiting event & hide the registration with -supportevent.
# This requires that you exit from the commandline (use the 'exit' command), closing the window with the 'x', ALT-F4 &c will not fire this event
Register-EngineEvent -SourceIdentifier powershell.exiting -SupportEvent -Action { Get-History -Count 100 | Export-Clixml (Join-Path (split-path $profile) history.clixml) }

# load previous history, if it exists
if ((Test-Path $historyPath)) {
    Import-Clixml $historyPath | ? {$count++;$true} | Add-History
    Write-Host -Fore White "`nLoaded $count history item(s).`n"
}

#endregion

Set-Location c:\powershell
