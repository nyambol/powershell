Set-StrictMode -Version 2.0

<# 
 .Synopsis
  Collection of functions and commands for working with WebTrends.

 .Description
  The items within this module are intended to be used for troubleshooting
  and maintaining WebTrends environments and to answer questions about
  report data.
 
 .Notes
  Compiled by Michael Powe, Technical Account Manager, WebTrends
  Last Modified:  $Date: 2012/09/26 15:23:14 $
#>

# $Id: WebTrends-Module.psm1,v 1.36 2012/09/26 15:23:14 powem Exp $
# PowerShell Module for WebTrends

#region System Operations

<#
The functions in this region primarily do system requirement checking on the 
loading of the module.  If items required for the loading of the module tools
are not found, then a warning will be issued.
#>

function Get-ModuleVersion{
<#
 .Synopsis
  Uses the CVS revision keyword to determine the current module number.
  
 .Description
  The 'Revision' Keyword of CVS sets the current revision number of the
  file.  This function splits out that number and returns it. This number
  is used to set the global variable in the session, so the current version
  of the module can always be determined by looking at the global variable
  $WMVersion.  This module is not exported.
#>
	$revision = "`$Revision: 1.36 $"
	$revNumber = $revision.trim("$").split(":")[1].trim()
	return $revNumber
}

function Get-WtModuleInfo{
<#
 .Synopsis
  Displays the names of the functions exported by this module and their aliases.
  
 .Description
  Displays the list of the function names that have been exported by this module
  in the current session.  Also, displays the aliases associated with the functions.
  These lists are dynamically generated, so they will be updated automatically as new
  functions are added to the module.
 
 .Notes
  This function looks at what is being exported by the module.  Other methods of looking
  inside the module may report on items that are not exported for use at the time.
#>

	begin {
		$funcs = Get-Module WebTrends-Module | Foreach-Object{$_.ExportedFunctions}
	}
	
	process {
		Write-Host "`nFunctions available via this module:`n"
		
		foreach ($k in $funcs.keys){ $k; }
		Write-Host "------------------------------------`n"
		Write-Host "Commandline aliases for WebTrends Module functions:`n"
		get-alias | ?{$_.ModuleName -eq "WebTrends-Module"} | Foreach-Object{$_.Name+"`t"+$_.Definition}
		Write-Host "------------------------------------`n"
		Write-Host "Variables set by this module:`n"
		Get-Variable | ?{$_.Description.Contains("WebTrends")}
		Write-Host "------------------------------------`n"
		Write-Host "All WebTrends Module functions have associated help files."
		Write-Host "Use Get-Help <function name> to get detailed information about the functions.`n"
	}
	
	end {
	
	}
}

function Get-OSInfo{
<#
 .Synopsis
  Write to the console a brief summary of information about the local computer.
  
 .Description
  Accesses WMI on the local system to capture some information about the system 
  and write it to stdout.  See notes (Get-Help Get-OSInfo -full) for an important
  caveat about using this function.

  Throws System.ArgumentException if the current user is not an Administrator.
  
 .Outputs
  To console.
  
 .Notes
  You must have WMI service running on the local system and it must be accessible
  to the user (e.g., if you are logged into a non-admin user account, you probably
  will not have access to WMI.  In that case, this function will fail.)
#>
	begin{
		$wi = [System.Security.Principal.WindowsIdentity]::GetCurrent()
		$wp = new-object 'System.Security.Principal.WindowsPrincipal' $wi
		
		if (-not($wp.IsInRole('Administrators'))){
			Write-Host 
            throw [System.ArgumentException] "This login is not in the Administrators group.";
		}
		
		$build = @{n="Build";e={$_.BuildNumber}}
		$SPNumber = @{n="SPNumber";e={$_.CSDVersion}}
		$sku = @{n="SKU";e={$_.OperatingSystemSKU}}
		$hostname = @{n="HostName";e={$_.CSName}}
	}
	process {
		$Win32_OS = Get-WmiObject Win32_OperatingSystem -computer "." | select $build,$SPNumber,Caption,$sku,$hostname, servicepackmajorversion
		
	}
	end {
		$Win32_OS
	}
}


function Test-Pscx {
<#
 .Synopsis
  Returns TRUE if the Pscx module is installed, FALSE otherwise.
  
 .Description
  Tests to see if the PowerShell Community Extensions are installed. The 
  extensions are used by some functionality in the WebTrends module and 
  are a required dependency.
#>
	if(Get-Module -Name "Pscx"){
		return $true
	} else {
		return $false
	}
}

function Get-FrameworkVersion{
<#
 .Synopsis
  Returns the value of the version for the latest .NET Framework installed.
  
 .Description
  Relies on a brute force search of the registry keys for .NET Framework installations.
  Back traces from version 4 until it finds one. If nothing is found, returns '0.0'
  for the version.
#>
	begin{
		$currentVersion = 0.0
	}
	process {
		if (Test-Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'){
			gp 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | Foreach-Object{$currentVersion = $_.Version}
		} elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5'){
			gp 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1033' | Foreach-Object{$currentVersion = $_.Version}
		} elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0'){
			gp 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0\Setup' | Foreach-Object{$currentVersion = $_.Version}
		} elseif (Test-Path (gci 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' | ?{$_.Name.Contains("v2")}).PSPath){
			gci 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' | ?{$_.Name.Contains("v2")} | gp | Foreach-Object{$currentVersion = $_.Version}
		}
	}
	end {
		$currentVersion
	}
}

function Test-FrameworkVersion {
<#
 .Synopsis
  Tests if the installed .NET Framework meets the required version number.
  
 .Description
  Uses Get-FrameworkVersion to find the current installed version, then compares it
  to the required version.  Required defaults to '4.0'.  Returns true if the 
  installed version is greater than required, false otherwise.
 
 .Parameter Required
  Version of the framework to be tested.  Defaults to 4.0.
  
 .Parameter Boolean
  Optional switch that causes the test to operate as a simple true/false boolean,
  rather than writing a result message to the console.
#>
	param($required = 4.0, [switch]$boolean)
	$current = Get-FrameworkVersion
	
	if($boolean){
		if($current -lt $required){
			return $false
		} else {
			return $true
		}
	}
	
	if ($current -lt $required){
		Write-Host ("Current version of the .NET Framework,", $current, "does not meet the required", $required)
		$false
	} else {
		Write-Host ("Current version of the .NET Framework,", $current, "meets or exceeds the required", $required)
		$true
	}
	
}

function Get-PSVersion {

<#
 .Synopsis
  Return the version of Powershell logged into.
 
 .Description
  There's no version of PowerShell immediately available in version 1.0,
  so if there's no $PSVersionTable found, then the version is identified
  as version 1. 
#>
    if (test-path variable:psversiontable) {
		$psversiontable.psversion.toString()
	} else {
		[version]"1.0.0.0"} 
}

function Test-PSVersion {
<#
 .Synopsis
  Boolean test of the installed version of PowerShell.
  
 .Description
  By default, returns TRUE if the version is 2.0, FALSE if less
  (i.e., version 1)  Calls Get-PSVersion to determine the installed
  version of the shell.
  
 .Parameter Required
  Optional parameter to set the required version.  Defaults to 2.0.
#>
	param($required = 2.0)
	
	$version = Get-PSVersion
	if ($version -lt $required){
		return $false
	} else {
		return $true
	}
}

#endregion


#region Log File Processing

function Get-LogLines {
<# 
 .Synopsis
  Count the lines in a set of log files.

 .Description
  Takes the path to a set of log files and counts the lines in each according to
  a pattern for identifying them.  Presents the count for each file and a sum of
  all the lines.

 .Parameter Path
  Alias 'p'
  The collection of log files.  Defaults to "*.log" in the current directory

 .Parameter Pattern
  Alias 'r'
  The regular expression or string to be matched. Lines are identified for the count
  by a regular expression.  Default value is "GET|POST", which will capture nearly
  all legitimate log entries that would be considered page views.

 .Example
   # Cycle through all files of extension .log in the current directory, matching
   the default GET|POST pattern.
   
   Get-LogLines
   
   Description
   -----------
   In this most trivial case, the function is run in the current directory, using the defaults. 
   The defaults make it possible to use this bare function call to count all the log lines in
   the current directory for all files with the extension .log.

 .Example
   # Count the logs in a different directory, using a customized line identifier.
   
   Get-LogLines -Path c:\logs\*.log -Pattern "\.html|\.asp"
   
 .Notes
  Some manipulation of the search pattern can identify actual page files in the logs,
  when that is important.  The default is straight counting of every log line, suitable
  for SDC log files.
#>
	param(
		  [parameter(Mandatory=$false)]
		  [alias("p")]
		  [string]$path = "*.log", 
		  [parameter(Mandatory=$false)]
		  [alias("r")]
		  [string]$pattern = "GET|POST")	
	
	if(-not(Test-Path -Path $path -PathType Leaf)){
		throw [System.IO.FileNotFoundException] "Specified files not found in this directory."; 
	}
	$fcounts = @()
	$sum = 0
 	gci $path | Foreach-Object{$fcounts += (select-string -path $_.FullName -pattern $pattern).count}
	foreach ($f in $fcounts){
		$sum += $f
	}
	Write-Host ("`n----`nTotal logs processed:", $fcounts.Length)
	Write-Host ("Total lines:", $sum, "`n----`n")
}


function Rename-WtFiles {
<#
 .Synopsis
  Wrapper for renaming log files in the current directory.
	
 .Description
  This wrapper function for the Rename-Item cmdlet will rename all the 
  files in a directory.  By default it renames them to a .log extension.
	
 .Parameter Path
  The directory in which the files to be renamed are located
	
 .Parameter Ext
  The new extension to be appended to the log files
	
 .Example
  # Rename all the files in the current directory to .log extension
	
  Rename-WtFiles
	
 .Example
  # Rename all the files in the current directory to a backup file extension.
	
  Rename-WtFiles -Ext .bak
#>
	param([string] $path = ".", [string]$ext = ".log")
	
	if(-not(Test-Path -Path $path -PathType Container)){
		throw [System.IO.DirectoryNotFoundException] "The path is not a valid path."
	}
	gci -Path $path | Rename-Item -NewName {$_.FullName + $ext}
}

function Backup-WtLogs{
<#
 .Synopsis
  Gzip the files in a directory and move the gzipped files to an archive directory.
 
 .Description
  The files in the specified directory are individually compressed with gzip and the
  compressed files are moved to an archive directory.  With the optional -remove switch,
  the original uncompressed logs can be deleted.  Deletion is dependent on confirmation
  that a gzipped copy exists in the archive directory.
 
 .Parameter Source
  The source directory containing the log files.
 
 .Parameter Archive
  The target or archive directory to which files are to be backed up.
 
 .Parameter LogExt
  The extension of the files to be processed.  Defaults to .log.
 
 .Parameter ArcExt
  The extension created by the gzip process.  Defaults to .gz.
 
 .Parameter Remove
  Optional switch to cause the original uncompressed files to be deleted.
 
 .Example
  # Gzip the log files in the source directory and move the gzipped copies to the archive.
  
  Backup-WtLogs -source $env:clients\coke\coke_logs -archive c:\logs\coke
  
  Description
  -----------
  A plain gzip and move routine that leaves the originals in place.  Note that the specified
  directories do not include trailing slashes or wildcards.
  
 .Example
  # Gzip, move and remove the originals
  
  Backup-WtLogs -source . -archive c:\logs\coke -remove
  
  Description
  -----------
  Use of the -remove switch causes the backup process to check the files in the original source
  directory against those in the archive directory.  If a gzipped file is found that contains
  the file name of an original source file, then the source file is deleted.  This helps to insure
  that no originals will be deleted without a verified backup copy.
 
 .Notes
  The Move-Item command will not clobber an existing file.  If a source file is gzipped and the
  archive directory contains a gzipped file of the same name, the move will fail for that file
  only.  Move-Item will continue processing with the next file.  The gzipped file will remain in
  the source directory.  Thus, this backup process should not be run against live files that are
  being updated.  Further, it is possible to inadvertently delete the wrong file if the -remove 
  option is used and the move fails because of the noclobber property.
#>
	param(
	[parameter(Mandatory=$false)]
    [alias("s")]
	[string]$source = ".",
	[parameter(Mandatory=$true)]
    [alias("a")]
    [alias("dest")]
	[string]$archive,
	[parameter(Mandatory=$false)]
    [alias("ext")]
	[string]$logext = "*.log", 
	[parameter(Mandatory=$false)]
	$arcext = "*.gz",
	[parameter(Mandatory=$false)]
	[switch]$remove)
	
	if (-not(Test-Path -Path $source -PathType Container)){
		throw [System.IO.DirectoryNotFoundException] "The source path is not correct."
	}
	if (-not(Test-Path -Path $archive -PathType Container)){
		throw [System.IO.DirectoryNotFoundException] "The target path is not correct."
	}
	
	if ($source.EndsWith("\")){
		$source = $source.substring(0,$source.Length-1)
	}
	if ($archive.EndsWith("\")){
		$archive = $archive.substring(0,$archive.Length-1)
	}
	if (-not($source.EndsWith("\*"))) {
			$source += "\*"
	}
	
	gci $source -Include $logext | ForEach-Object {Write-GZip $_.FullName}
	gci $source -Include $arcext | Move-Item -Destination $archive
	
	if($remove){
		$originals = gci $source -Include $logext
		$archive += "\*"
		$archives = gci $archive -Include $arcext
		
		foreach($log in $originals){
			foreach($gzip in $archives){
				if($gzip.Name.Contains($log.Name)){
					Remove-Item $log.FullName
					break;
				}
			}
		}
	}
}


#endregion


#region Webtrends Data Processing

function Find-WtString{
<# 
 .Synopsis
  Find a given string or substring value in a set of log files.

 .Description
  Captures strings or substrings based on a given regular expression and writes
  the resulting captures to a file.  Designed specifically to work on web log files,
  either SDC or web server logs.
  
  Throws System.IO.FileNotFoundException if no log files are found in the
  current directory.

 .Parameter Query
  Alias 'q'
  Switch to identify the search as taking place in the query string field.

 .Parameter target
  Alias '-s'
  The regular expression or string to be searched. The search is a regular expression
  search, so if the string passed in is not in regular expression format with a capture
  group, a capture group will be added to it.

 .Parameter File
  Alias '-f'
  Pass in a single file name instead of relying on the default '*.log'.

 .Example
  # Capture all the URLs in the cs-uri-stem field.
   
  Find-WtString "[ ]+GET[ ]+([^ ]+).*"
   
  Description
  -----------
  This regular expression looks for the text field immediately following the 
  cs-method field containing the GET method.  It then captures everything up 
  to the next space character.

 .Example
  # Capture all the values of the query parameter WT.mc_id that consist of exactly the string PUB_WWW_F.
   
  Find-WtString "WT\.mc_id=(PUB_WWW_F)&"
   
  Description
  -----------
  Without the -query switch, the search string must specify exactly how to 
  capture a value within the query string.  This means specifying either a 
  terminating ampersand or end-of-string (probably a space).

 .Example
  # Capture all values of the query parameter WT.mc_id.  
	 
  Find-WtString -query WT.mc_id
   
  Description
  -----------
  Using the -query switch causes the function to treat the given string as a
  parameter name and look for the _values_ within the query string, rather than
  looking for the string itself.
#>
	param(
		  [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		  [alias("f")]
          [alias("Fullname")]
		  [string]$file,
		  [switch]
		  [parameter(Mandatory=$false)]
		  [alias("q")]
		  $query, 
		  [parameter(Mandatory=$true)] 
		  [alias("s")]
          [alias("t")]
		  [string]$target
		 )
	
	begin {
		$stime = Get-Date
		$filecount = 0;
		$original = ($target -replace "[*./\[\]+^&()=|\\?]",'_')
		$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
		[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
		$path = (Get-Location).Path
		$files = "*.log";
	 	
		if ( -not((ls $files).length -gt 0) -and -not($file)){ 
	 		throw [System.IO.FileNotFoundException] "Specified files not found in this directory.";
		}

        if($file){
            $filecount = 1;
        } else {
            $filecount = (gci -Filter $files).Count;
        }
		
		if ($query){
		    if (-not($target.Contains("(")) -and -not($target.Contains("=")) ){
		         $target += "=([^& ]+)"
		    } elseif ($target.Contains("=") -and -not($target.Contains("("))){
		         $stemp = $target.split("=")
		         $stemp[1] = "({0}[^& ]+)" -f $stemp[1]
				 $target = ("{0}={1}" -f $stemp[0], $stemp[1])
			}
		} else {
			if (-not($target.Contains("(")) ){
				$target = "(" + $target + ")";
			}
		}
		
		# -----------------------------------------------------------------------------		
		# define an inner function to process the files
		function innerProcessFile
		{
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
              $lines = @();
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
                      $lines += $line;
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
		      new-object psobject -prop @{TotalCount = $totalCount; Unique = ([string[]]$set.Keys); Lines = [string[]]$lines}
		   }
		} # end innerProcessFile function
		# 	end inner function definition
		# -----------------------------------------------------------------------------
	
		Write-Host ("Searching files on {0} for {1}" -f $path, $target)
	} # end begin block
	
	process{
			if ($file){
				$results = gci $file | innerProcessFile -Pattern $target  -Group 1;
			} else {
				$results = gci -Filter $files | innerProcessFile -Pattern $target  -Group 1;
			} 
	}
	end {
        $strmatch = "";
        $linestr = "";
        if($results.Unique.Length -eq 0){
            $strmatch = "No items matched in the file or files processed.";
            $linestr = "No lines matched in the file or files processed.";
        } else {
	    	$strmatch = [String]::Join("`n",@($results.Unique | sort -Descending));	
            $linestr = $results.Lines -join "`n";
        }
        	
		Set-Content -Path ("{0}\Desktop\{1}_found_{2}.log"       -f $env:USERPROFILE, $original, $datestamp ) $strmatch;
        Write-Host ("{0}\Desktop\{1}_lines_found_{2}.log" -f $env:USERPROFILE, $original, $datestamp );
        Set-Content -Path ("{0}\Desktop\{1}_lines_found_{2}.log" -f $env:USERPROFILE, $original, $datestamp ) $linestr;
     	$bytes = 0;
		$units = "MB";
		ls $files | %{$bytes += $_.Length};
		$mb = ($bytes/1024)/1024;
		if ($mb -gt 1024){
			$mb = $mb/1024;
			$units = "GB";
		}
		
		# write processing time to console
		$etime = Get-Date;
		$ptime = $etime - $stime;
		$hrfmt = $minfmt = $secfmt = "0:0#";
		$fmt = "0:##";
		if($ptime.Hours -lt 10){
			$fmt = $hrfmt;
		}
		if($ptime.Minutes -lt 10){
			$fmt = $minfmt;
		}
		if($ptime.Seconds -lt 10){
			$fmt = $secfmt;
		}
        
		Write-Host ("Processed {0} files, {4,0:#.##} {5}, in {1,$fmt}:{2,$fmt}:{3,$fmt}." -f $filecount, $ptime.Hours,$ptime.Minutes,$ptime.Seconds, $mb, $units);
		Write-Host "`nFinished."
	}
}

function Find-WtQueryStringPair{
<# 
 .Synopsis
  Find a given pair of query parameter values in a set of log files.

 .Description
  Captures strings or substrings in the query string, based on a given regular expression 
  and writes the resulting captures to a file.  Designed specifically to work on web log files,
  either SDC or web server logs.  The search will be made for 'initial' and then the
  results of that search will be used to find 'secondary.'  Thus, the final result will be,
  "all those instances in which an entry containing 'initial' also contained 'secondary'."
  
  Throws System.IO.FileNotFoundException if there are no log files in the current directory.

 .Parameter initial
  Alias 'i'
  The first string pattern to match.  This result of this search will be the basis
  for the second search.  This pattern should be a regular expression.  If it does not
  include a capture group, the entire pattern will be treated as a capture group.

 .Parameter secondary
  Alias 's'
  The second string pattern to match.  This pattern will be searched in the output of
  the first search. This pattern should be a regular expression.  If it does not
  include a capture group, the entire pattern will be treated as a capture group.

 .Outputs
  A file containing the values returned by the search for 'initial', followed by a count
  of the number of times it was found, followed by the values of 'secondary' which were
  found associated with 'initial'.  
  e.g., 200000019537133 = 4 77581893 77581893 77581893 416203966
#>
	param(
		  [parameter(Mandatory=$true,
		   			 HelpMessage="First pattern is the one to be linked to by the second.")]
					 [alias("i")]
					 [string]$initial, 
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Second pattern will be associated with the first.")]
					 [alias("s")]
					 [string]$secondary
		 )
	
	begin {
		$firstitems = 0
		$seconditems = 0
		$wtmatches = @{}
		[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
		$path = (Get-Location).Path
		$original = ($initial -replace "[*./\[\]+^&()=|\\?]",'-') + "_" + ($secondary -replace "[*./\[\]+^&()=|\\?]",'-')
		$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
		$logs = (gci * | Where-Object{$_.Extension -eq ".log" })
		
	 	if ($logs -eq $null){ 
	 		throw [System.IO.FileNotFoundException] "Log files not found in this directory.";
		}
		if (-not($initial.Contains("(")) -and -not($initial.Contains("=")) ){
	         $initial += "=([^& ]+)"
	    } elseif ($initial.Contains("=") -and -not($initial.Contains("("))){
	         $stemp = $initial.split("=")
	         $stemp[1] = "("+$stemp[1]+"[^& ]+)"
	         $initial = $stemp[0]+"="+$stemp[1]
	    }
		if (-not($secondary.Contains("(")) -and -not($secondary.Contains("=")) ){
	         $secondary += "=([^& ]+)"
	    } elseif ($secondary.Contains("=") -and -not($secondary.Contains("("))){
	         $stemp = $secondary.split("=")
	         $stemp[1] = "("+$stemp[1]+"[^& ]+)"
	         $secondary = $stemp[0]+"="+$stemp[1]
	    }
	}
	process {
	    Write-Host "Searching files on $path for $initial and $secondary"
		$first = (select-string -Path *.log -Pattern $initial)
		if ($first -ne $null){
			$second = ($first | %{if($_.Line -match $secondary){$_}})
			$first | Foreach-Object{
				$wtmatches[$_.Matches[0].Groups[1].Value]++; 
				$firstitems++
			}
		}
		if ($second -ne $null){
			$second | Foreach-Object{ 
			if($_.Line -match $secondary){} # Sets $matches
				# if the key already exists for the current value, add the
				# array to $val and then add the new value and then insert
				# the updated array into the table.
				# if the key doesn't already exist then it will be added 
				# and pointed to the current table value.
				$val = @()
				if (($wtmatches.keys) -contains ($_.Matches[0].Groups[1].Value)) {
					$val += $wtmatches[$_.Matches[0].Groups[1].Value]
				}
				$val += $matches[1]
				$wtmatches[$_.Matches[0].Groups[1].Value] = $val}
		}
	    if ($wtmatches.Count -gt 0){
			$strmatch = @();
			$strmatch += "Total line count of matching items was {0}" -f $firstitems
			$strmatch += "Total unique items is {0} " -f $wtmatches.Count
			$strmatch += "----"
			$strmatch += "{0},Hit Count,{1}" -f $initial,$secondary
			$wtmatches.GetEnumerator() | Sort-Object -Property Value -Descending |
			Foreach-Object{$strmatch += $_.key + "," + [system.string]::Join("`n,,",$_.Value)}
			Set-Content -Path ("{0}\Desktop\{1}_found_{2}.csv" -f $env:USERPROFILE, $original, $datestamp ) $strmatch
			Write-Host ("`nFound {0} matching lines." -f $firstitems)
	        Write-Host ("Wrote {0} unique items to file." -f $wtmatches.Count)
	    } else {
	         Write-Host "No matches found."
	    }	
	}
	end {
     	Write-Host "`nFinished."
	 }
}

function Test-WtTransactions {
<#
 .Synopsis
  Test all the lines in a set of log files that have WebTrends transaction parameters and validate the transaction formatting.
 
 .Description
  This function parses a set of log files and looks for entries that have the transaction 
  invoice parameter. It then checks for the required transaction parameters and validates 
  that they have the proper formatting.
  
 .Notes
  This function will validate date and time formats and match transactions
  that have multiple items (e.g., WT.tx_s=8.49;6.23;8.09). But it does
  not verify that all the parameters carrying multiple values are
  carrying the same number of values.

#>

	begin{

		# check that we're in a log directory
		
		if((gci *.log) -eq $null){
			throw [System.IO.FileNotFoundException] "No log files found in this directory.";
		}
		
		
		$transactions = New-Object psobject -Property @{cvalues=@{};ivalues=@{};clines=@();ilines=@()} 
		
		$invoice = "WT.tx_i=(?<inv>[^ &]+)";
		$invdate = "WT.tx_id=(?<dt>[^ &]+)";
		$invtime = "WT.tx_it=(?<tm>[^ &]+)";
		$sub = "WT.tx_s=(?<sub>[^ &]+)";
		$units = "WT.tx_u=(?<un>[^ &]+)";
		$sku = "WT.pn_sku=(?<sk>[^ &]+)";
		$event = "WT.tx_e=(?<ev>[^ &]+)";
		
		# regular expressions for matching
		# invoice is any character/digit string
		$txi   = "WT.tx_i=(?<invoice>[^ &]+&)"
		# date is 00/00/00 or 00/00/0000
		$txid  = "WT.tx_id=(?<date>\d{2}(%2F|/)\d{2}(%2F|/)\d{2,4})"
		# time is 00:00:00
		$txit  = "WT.tx_it=(?<time>\d{2}(%3A|:)\d{2}(%3A|:)\d{2})"
		# subtotal is 00.00[;00.00]
		$txs   = "WT.tx_s=(?<subtotal>(\d+\.\d+)(;\d+\.\d+)*[& ])"
		# units is digits
		$txu   = "WT.tx_u=(?<units>\d+(;\d)*[& ])"
		# product number is any chars/digis
		$pnsku = "WT.pn_sku=(?<sku>[^&]+(;[^&]+)*[& ])"
		# event is 'p' for purchase
		$txe   = "WT.tx_e=p"
		
		$inv = Select-String -Path *.log -Pattern $txi
		
		# no transactions in the log files
		if ($inv -eq $null){
			throw [System.ArgumentNullException] "No transactions in log files."
		} else {
			Write-Host("Found {0} instances of {1} in the file ..." -f $inv.Count, $invoice);
			Write-Host "Testing ...";
		}
	} # end begin
	
	process{
	
		# match all the lines that have valid transaction parameters
		$trans = $inv | 
			?{($_.Line -match $txid) -and
			  ($_.Line -match $txit) -and
			  ($_.Line -match $txs) -and
			  ($_.Line -match $pnsku) -and
			  ($_.Line -match $txe)
			 }
			 
		
		
		$mistakes = $inv |
			?{($_.Line -match $invdate -and $_.Line -notmatch $txid)  -or
			  ($_.Line -match $invtime -and $_.Line -notmatch $txit)  -or
			  ($_.Line -match $sub     -and $_.Line -notmatch $txs )  -or
			  ($_.Line -match $sku     -and $_.Line -notmatch $pnsku) -or
			  ($_.Line -match $event   -and $_.Line -notmatch $txe)
			}
		
		
			
		# if no matching lines for mistakes, create an empty
		# object which will have an item count of zero.
		if($mistakes -eq $null){
			$mistakes = @{};
		}
		
		# if no matching lines for transactions, create an empty
		# object which will have an item count of zero.
		if ($trans -eq $null){
			$trans = @{}
		}
	} # end process
	
	end{
		$diff = $inv.Count - $trans.Count
		
		Write-Host ("Total invoice lines:     ",$inv.Count)
		Write-Host ("Valid transaction lines: ",$trans.Count)
		Write-Host ("Invalid transactions:    ",$mistakes.Count)
		return $transactions;
	}
}

function ConvertTo-WtDemoLog{

<#
 .Synopsis
  Convert a log file to a demo log by modifying a field, based on the value of a reference field.
  
 .Description
  Uses a hashtable to add parameter to a specified target field in an SDC log, based
  on values in a reference.  The origin of this function was the requirement to produce
  a demo of a customized version of the Traffic Sources report, based on the contents 
  of the referrer.  By default, the reference field is the referrer and the target
  field is the query string field.
  
 .Parameter Infile
  Required. The file to be converted
  
 .Parameter Outfile
  Required. The file to write as the conversion.
  
 .Parameter Modifiers
  Required.  A hashtable consisting of strings to match in the reference for the keys, and the
  values to be added to the target.  The values field should be exactly what is to be
  included. e.g., to added a parameter to the query string, the value in the hashtable should
  be of the format "<parameter>=<value>&".
  
 .Parameter Matcher
  Optional.  A substitute regular expression for matching the log lines.  This must match the 
  entire log line and not just a portion of it. The default built-in matcher matches the 
  referrer for the reference field and the query string for the target field to be modified. The 
  field to be matched must be labeled 'reference' and the field to be modified must be labeled
  'target'.  See Notes for information about labeling.
  
 .Parameter Append
  Optional.  The default is to prepend the new value to the target string. Use this optional
  switch to force the modification to be appended to the target string.
  
 .Inputs
  A log file in standard SDC format (not an OnDemand file created by the tag server)
  
 .Outputs
  A converted version of the input file, with the specified parameter added to the query strings.
  
 .Example
  {powem} [9]-->  $sources = @{"playstation.com/search-results" = "WT.tsrc=Internal%20-%20Search";
  >> "google" = "WT.tsrc=Search%20-%20Google";
  >> "yahoo" = "WT.tsrc=Search%20-%20Yahoo";
  >> "bing" = "WT.tsrc=Search%20-%20Bing";
  >> }
  >>
  {powem} [25]-->  Invoke-History -Id 14
  ConvertTo-WtDemoLog -infile .\dcs3orc8j100004j5oatrta79_2w4j-dcs-2011-12-31-00-00000-cetcnt002.log 
  -outfile .\trafficsources.log -modifiers $sources
 
 .Notes
  If you want to use this function with a tag server file, you have to modify the regular expression for
  matching the log lines because the tag server file has extra fields in it.
  
  The regular expression for matching the log lines must include the named capture "reference" for the
  match to be looked at and "target" for the capture to be modified.
  
  Syntax for named captures in PowerShell regular expressions:  (?<target>[^ ]+)
  
  Values are prepended to the target field by default.
  
#>

	param(
	[string] $infile = $(Read-Host -Prompt "Input File (absolute or relative path): "),
	[string] $outfile = $(Read-Host -Prompt "Output File (absolute or relative path): "), 
	[hashtable] $modifiers = {$m = (Read-Host -Prompt "Hashtable to be used for modifiers: "); ls variable: | ?{$_.Name -eq $m} },
	[switch]$append,
	[string]$matcher)
	
	$content = Get-Content $infile
	
	[string] $default_regex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<target>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<reference>[^ ]+) [^ ]"
	[string] $regex = ""
	
	if ($matcher){
		$regex = $matcher
	} else {
		$regex = $default_regex
	}
	
	$content | Where-Object {$_ -match $regex}|
	ForEach-Object {
		foreach ($s in $modifiers.keys){
			if (($matches.reference).Contains($s)){
					if(-not($append)){
						$_ = $_ -replace $matches.target,($modifiers[$s]+$matches.target)
					} else {
						$_ = $_ -replace $matches.target,($matches.target+$modifiers[$s])
					}
					break;
				} 
		}
		Add-Content -Value $_ -Path $outfile
	}
}

function Set-wtRestHash{

<#
 .Synopsis
  Create a hash with the information necessary for the call to the REST API.

 .Description
  The call to the REST API requires a set of configuration data.  The function
  Get-RestData expects a hashtable with the necessary information.  This function
  can be used as a shortcut to creating that hash.

  $restConfig = @{version="v3";
				profile="21897";
				report="hGgJLBjviR6";
				type="indv";
				totals="none";
				format="html";
				measures="measures=0*1*2";
				user="acct\login";
				pass="password"}
  
  The username and password are optional.  If they are not present in the hashtable
  when it is passed into the data collection function, then the function will prompt 
  for them.  The additional option is to put the name = value pairs into a file and
  then read the file and process it into the hashtable.

 .Notes
  If you put the username into the file, you must escape the backslash, e.g. 
  "coca-cola\\wt-mpowe."  However, this escaping is not necessary if you enter the
  name at the console command prompt.

#>

	param([parameter(Mandatory=$false)] [alias("v")] $version,
		  [parameter(Mandatory=$false)] [alias("pr")] $profile,
		  [parameter(Mandatory=$false)] [alias("r")] $report,
		  [parameter(Mandatory=$false)] [alias("ty")] $type,
		  [parameter(Mandatory=$false)] [alias("to")] $totals,
		  [parameter(Mandatory=$false)] [alias("fo")] $format,
		  [parameter(Mandatory=$false)] [alias("m")] $measures,
		  [parameter(Mandatory=$false)] [alias("u","name")] $user="",
		  [parameter(Mandatory=$false)] [alias("pw","password")] $pass="",
          [parameter(Mandatory=$false)] [alias("f")] $file
		 )
	
	$restConfig = @{}
	
    if($file -ne $null){
        if ((Test-Path -Path $file) -eq $false){
            throw [System.IO.FileNotFoundException] ("Specified configuration data file [{0}] was not found." -f $file);
        }
        $data = Get-Content -Path $file;
        [string]$params = "";
        $data | %{$params += $_+"`n"};
        $restConfig = ConvertFrom-StringData -StringData $params;
    } else {
	    $restConfig.version = $version
	    $restConfig.profile = $profile
	    $restConfig.report = $report
	    $restConfig.type = $type
	    $restConfig.totals = $totals
	    $restConfig.format = $format
	    $restConfig.measures = "measures={0}" -f $measures
	    $restConfig.user = $user
	    $restConfig.pass = $pass
	}
	return $restConfig
}

function Get-wtRestData{

<#
 .Synopsis 
  Retrieve report data from WebTrends via REST API.
 
 .Description
  A simple retrieval mechanism for REST data from WebTrends API.  Pass in 
  the start and end dates in proper format.   Use a hashtable for the other 
  essential values.  This function builds the data request for report data 
  only.
  
  The data is collected in an object, which is returned from the function.
  The object contains a property 'Count', which can be used to see the size
  of the returned data string.  The property 'Data' contains the full string
  returned in response to the request.
  
 .Parameter Start
  The start date in proper format, e.g. 2011m01d01.
  
 .Parameter End
  The end date in proper format.
  
 .Parameter Conf
  A hashtable containing configuration information for the data pull.  The 
  hashtable should contain the following elements:
  version,profile ID, report GUID, type (agg,indv or trend), totals 
  (all, none or only), format (html, json, xml or xml2),  measures 
  (measures=0*1*3 or measures=99 for all measures), username (acct\login), 
  password.
  -----
  
  $restConfig = @{version="v3";
				profile="21897";
				report="hGgJLBjviR6";
				type="indv";
				totals="none";
				format="html";
				measures="measures=0*1*2";
				user="acct\login";
				pass="password"}
  
 .Outputs
  An object that contains the data retrieved and a count indicating the length of the data.
  
 .Notes
  This function uses the StreamReader method ReadToEnd(), so a huge data response may break.
  The usual breakage is that the server closes the stream.  I assume that this happens 
  because the server has a built-in limit to the amount of data it will return in a single
  request. The solution is to chunk up the requests and then reassemble the chunks after
  they've all been retrieved.

  The username and password may be omitted from the hashtable, if desired.  In that case, 
  the function will prompt for them.  The password will be read in as a secure string; and  
  then the plain text will be recovered inside the script.  This is "security through 
  obscurity," since the text is easily recoverable by the script.  However, it does have 
  the feature of not storing the password in plain text in a file.

  To export to an HTML file, use something like:
  $data.Data | Set-Content -Path "C:\Users\powem\Desktop\test.html"
  
  Some trivial exception handling is included, which may prevent falling into an infinite
  loop of errors if something goes wrong.
#>

	param (
	[parameter(Mandatory = $true)] [string]$Start,
	[parameter(Mandatory = $true)] [string]$End,
	[parameter(Mandatory = $true)] [hashtable]$Conf,
    [parameter(Mandatory = $false)] [string]$user="",
    [parameter(Mandatory = $false)] [string]$pass="")

    begin{
        # This function cribbed from Oison Grehan, PS MVP
        function ConvertTo-PlainText( [security.securestring]$secure ) {
            $marshal = [Runtime.InteropServices.Marshal]
            return $marshal::PtrToStringAuto( $marshal::SecureStringToBSTR($secure) )
        }
	
	    $version = $Conf.version
	    $profile = $Conf.profile
	    $report = $Conf.report
	    $type = $Conf.type
	    $totals = $Conf.totals
	    $format = $Conf.format
	    # put in a nonsense number to include all measures
	    $measures = $Conf.measures
        if($Conf.ContainsKey("user") -eq $false -and $user -eq ""){
            $user = Read-Host "Enter the username (domain\user format)";
        }
        if($Conf.ContainsKey("pass") -eq $false -and $pass -eq ""){
            $secure = Read-Host -AsSecureString "Enter the password";
            $pass = ConvertTo-PlainText $secure;
        }
	
	    #$URL = "https://ws.webtrends.com/$version/Reporting/profiles/$profile/reports/$report/?totals=$totals&start_period=$start&end_period=$end&period_type=$type&$measures&format=$format&suppress_error_codes=true"
	    $URL = "https://ws.webtrends.com/{0}/Reporting/profiles/{1}/reports/{2}/?totals={3}&start_period={4}&end_period={5}&period_type={6}&{7}&format={8}&suppress_error_codes=true" -f `
	    $Conf.version, `
	    $Conf.profile, `
	    $Conf.report, `
	    $Conf.totals, `
	    $Start, $End, `
	    $Conf.type, `
	    $Conf.measures, `
	    $Conf.format
	
        if($Conf.ContainsKey("user") -eq $false){
            $Username = $user;
        } else {
            $Username = $Conf.user;
        }
	    if($Conf.ContainsKey("pass") -eq $false){
            $Password = $pass;
        } else {
	        $Password = $Conf.pass
        }

	    $UserAgent = $env:USERNAME+":"+$env:COMPUTERNAME

	    $restData = "" | Select-Object Count,Data

	    $URI = New-Object System.Uri($URL,$true)
	    $request = [System.Net.HttpWebRequest]::Create($URI)

	    $request.UserAgent = $(
	    "{0} (PowerShell {1}; .NET CLR {2}; {3})" -f $UserAgent, 
	    $(if($Host.Version){$Host.Version}else{"1.0"}),
	    [Environment]::Version,
	    [Environment]::OSVersion.ToString().Replace("Microsoft Windows ", "Win"))

	    #Establish the credentials for the request

	    $creds = New-Object System.Net.NetworkCredential($Username,$Password)

	    $request.Credentials = $creds
	}
    process {
	    # Thrown if the request times out
	    trap [System.Net.WebException] { "A web exception was thrown, possibly caused by a timeout: $_"; break; }

	    $response = $request.GetResponse()
	    $reader = [IO.StreamReader] $response.GetResponseStream()
	
	    # thrown by ReadToEnd()
	    trap [System.IO.IOException] { "An IO exception occurred on StreamReader: $_"; break }
	    trap [System.OutOfMemoryException] { "An OutOfMemoryException occurred on StreamReader: $_"; break }
	
	    $responseHTML = $reader.ReadToEnd()
	
	    $restData.Data = $responseHTML
	    $restData.Count = ($restData.Data).Length
	    }
    end{
	    if ($reader -ne $null){
		    $reader.Close()
	    }
	    if ($response -ne $null){
		    $response.Close()
	    }
	
	    return $restData
    }
}

function Get-WtUrlQuery{

<#
 .Synopsis
  Retrieve a hash of query parameter values with an array of URL
  
 .Description
  By default the function searches for some predefined parameters relevant
  only to one account.  Use the command line parameters to pass in a 
  query parameter name (e.g., WT.z_custom) and a regular expression to 
  capture the value.  The regular expression must include a capture group.
  The capture group is used as the hash key to organize the URLs 
  associated with the parameters.
  
 .Parameter Parameter
  The name of the parameter to be matched, e.g. WT.z_customParam.
  
 .Parameter Value
  A regular expression that will capture the parameter value, e.g. 
  (?<value>sw[^&]+).  Use named capture group with the name 'value'.
 
 .Parameter Counter
  Specifies that a counter should print to the console a line count.
  This is useful if you want to see how many lines are processed and
  if you want some visual confirmation that something is happening (if
  the process seems to be taking extraordinarily long to complete).
#>

	param([parameter(Mandatory=$true,
					 HelpMessage="Specify the URL parameter to be matched.")] [string] $parameter = "nit_g_market",
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Specify a regular expression to match the parameter value, that includes a named capture group")] [string] $value = "(?<value>sw[^&]+)",
		  [parameter(Mandatory=$false)] [switch] $counter
		 )

	begin {
		
		$wt = "" | Select-Object Regex, Collect, Item, Lines
		$wt.Item = ("{0}={1}" -f $parameter, $value)
		$wt.Regex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<host>[^ ]+) [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"
		$wt.Collect = @{}
		$wt.Lines = 0
	}
	
	process {
		gci *.log | Select-String -Pattern $wt.Regex |  select -ExpandProperty Matches | 
		ForEach-Object {
			if ($_.groups["query"].value -match $wt.Item){
				if ($wt.Collect.keys -contains $matches.value ) {
					$wt.Collect[$matches.value] += $_.groups["uri"].value
				} else {
					$wt.Collect[$matches.value] = @($_.groups["uri"].value)
				}	
			}
			if ($counter){
				if (($wt.Lines++ % 1000) -eq 0){
					Write-Host ("Processed {0} lines" -f ($wt.Lines-1))
				}
			}
		}
	}
	
	end {
		# you have to make a separate array of the keys to enumerate and
		# change the hash, otherwise modifying the hash breaks the enumerator
		foreach ($k in @($wt.Collect.keys)){
			$wt.Collect[$k] = $wt.Collect[$k] | select -Unique
		}
		return $wt
	}
}

function Find-WtQuery {

<#
 .Synopsis
  Takes a query parameter and returns all its unique values in a set of logs.
  
 .Description
  This function is intended to be used on large collections of large files that have
  the potential to take an unacceptably long time to process using other methods. It
  requires that a regex capture group be passed in as the value to search for.
  
 .Parameter Target
  The parameter with capture group to find, e.g. WT.z_custom=([^ &]+).
  
 .Parameter Files
  The file wildcard to search, e.g. '*.log'
  
 .Outputs
  An object with an array of unique values and a count of total matched lines.
#>

	param(
		[Parameter(Mandatory = $true)] [string] $target,
		[Parameter(Mandatory = $false)] [string] $files="*.log"
	)
	
	begin{
		$stime = Get-Date
		
		[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
		$path = (Get-Location).Path
		
		if ( -not((ls $files).length -gt 0)){ 
	 		throw [System.IO.FileNotFoundException] "No log files found in the directory.";
		}
		
		$wt = "" | select File,Lines,Count
		$items = 0
		$wtmatches = @{}
		$original = ($target -replace "[*.\\?]",'_')
		$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
		
		if (-not($target.Contains("(")) -and -not($target.Contains("=")) ){
		         $target += "=([^& ]+)"
		    } elseif ($target.Contains("=") -and -not($target.Contains("("))){
		         $stemp = $target.split("=")
		         $stemp[1] = "({0}[^& ]+)" -f $stemp[1]
				 $target = ("{0}={1}" -f $stemp[0], $stemp[1])
		    }
# -----------------------------------------------------------------------------		
#region innerProcessFile function
		function innerProcessFile
		{
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
#endregion 
# -----------------------------------------------------------------------------
	}
	process{
		$results = gci -Filter $files | innerProcessFile -Pattern $target  -Group 1;
	}
	end{
		$etime = Get-Date;
		$ptime = $etime - $stime;
		Write-Host ("Processing time for {0} files was {1}:{2}:{3}." -f (gci -Filter $files).Count, $ptime.Hours,$ptime.Minutes,$ptime.Seconds);
		return $results;
	}
}

function Test-wtTransDateTime {
 
 <#
  .Synopsis
   Tests the values of WT.tx_id and WT.tx_it for conformance with format specifications.

  .Description
   The date and time values for Webtrends transaction tracking parameters must match the
   specifications given by Webtrends.  Failure to match these specifications will cause the
   revenue tracking to silently fail.  This function returns information about any bad values
   found in the log files.

 #>

 	begin {


        $files = gci *.log;
        if(-not($files.Length -gt 0)){
            throw [System.IO.FileNotFoundException] "No log files found in the directory.";
        }

		$invoice = "WT.tx_i=(?<inv>[^ &]+)";
		$invdate = "WT.tx_id=(?<dt>[^ &]+)";
		$invtime = "WT.tx_it=(?<tm>[^ &]+)";
		
		# regular expressions for matching
		# invoice is any character/digit string
		$txi   = "WT.tx_i=(?<invoice>[^ &]+)"
		# date is 00/00/00 or 00/00/0000
		$txid  = "WT.tx_id=(?<date>\d{2}(%2F|/)\d{2}(%2F|/)\d{2,4})"
		# time is 00:00:00
		$txit  = "(?<time>\d{2}(%3A|:)\d{2}(%3A|:)\d{2})"
		# subtotal is 00.00[;00.00]
		#$txs   = "WT.tx_s=(?<subtotal>(\d+\.\d+)(;\d+\.\d+)*[& ])"
		# units is digits
		#$txu   = "WT.tx_u=(?<units>\d+(;\d)*[& ])"
		# product number is any chars/digis
		#$pnsku = "WT.pn_sku=(?<sku>[^&]+(;[^&]+)*[& ])"
		# event is 'p' for purchase
		#$txe   = "WT.tx_e=p"

 		$dtformat = New-Object psobject -Property @{date=@();time=@();Lines=@()}
		
 
 	}
 	process{
	
		# validate dates and times
 		$files | %{ switch -regex -file $_.Fullname {
	 			$invdate 
				{ 
					$temp = $matches['dt'];
					if("WT.tx_id="+$temp -notmatch $txid)
					{
						$dtformat.date += $temp;
						$dtformat.Lines += $_;
					}
				}
				$invtime 
				{ 
					$temp = $matches['tm'];
					if($temp -notmatch $txit)
					{
						$dtformat.time += $temp;
						if ($dtformat.Lines -notcontains $_)
						{
							$dtformat.Lines += $_;
						}
					}
	 			}
 			}	
 		}
 	}
 	end 
	{
		Write-Host("Found {0} instances of improperly formatted dates" -f $dtformat.date.Length);
		Write-Host("Found {0} instances of improperly formatted times" -f $dtformat.time.Length);
		return $dtformat;
 	}
}


#endregion


#region Data Formatting

function ConvertTo-WtAsciiSeparator {
<#
 .Synopsis
  Convert improper separators in a text file to a standard ASCII character.

 .Description
  Designed to fix the export of drilldowns in data scheduler, which come out
  with the drilldown elements separated by the Group Separator, which is 
  completely broken in Excel or Calc.
  
 .Parameter Old
  Optional parameter to specify the character to be removed.  Defaults to
  the GS, HEX \x1D
  
 .Parameter New
  Optional parameter to specify the new ASCII character.  Defaults to the
  pipe symbol, '|'.
  
 .Parameter Csvfile
  Required parameter to specify the file to be modified.  This is expected
  to be a CSV file with the .csv file extension.
  
#>

	param([parameter(Mandatory=$false,
					 HelpMessage="The HEX identifier for the char to be replaced.  Default is \x1D, the Group Separator")] $old = "\x1D",
		  [parameter(Mandatory=$false,
		  			 HelpMessage="The new character.  Default is the pipe symbol, |.")] $new = "|",
		  [parameter(Mandatory=$true,
		  			 HelpMessage="The full path to the input file, if not in the current directory.") ] $csvfile
		 )
	
	$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
	$ext = "_fixed_{0}.csv" -f $datestamp
	
	(Get-Content $csvfile) -replace $old, $new | Set-Content ($csvfile -replace ".csv", $ext)
}

function ConvertTo-WtCsv {
<#
.SYNOPSIS
 Create a csv file from the hashtable created by Get-WtUrlQuery.

.DESCRIPTION
 The hashtable created by the function Get-WtUrlQuery consists of a parameter 
 value for the key and an array of URLs associated with the parameter value.
 You still must pass the output of the function to Out-File to get it to text.

#>
	param(
			[parameter(Mandatory=$true,
					  HelpMessage="A hashtable that will be enumerated and written out to csv.")] [hashtable] $hash
		 )
						

	begin {}
	
	process {
		$hash.GetEnumerator() | 
     		Foreach {$obj = new-object psobject `
			-prop @{Parameter=$_.Name}; [string]::join(",`n", $_.Value) | 
			Foreach {$i=2} {Add-Member NoteProperty "URL" $_ -Inp $obj; $i++} {$obj} } | 
     		Sort {$_.Parameter } -desc | ConvertTo-Csv -NoTypeInformation
	}
	
	end {}

}

function Write-WtNewChar{
 
 <#
  .Synopsis
   Regular expression replacement of a string in a file.
  
  .Description
   Pass in the string or character to be replaced and a string or character to
   do the replacement.  Reserved characters must be properly escaped.  Accepts
   input from a pipeline.
   
  .Outputs
   A new file with the string 'fixed' inserted in the filename of the original,
   and all occurrences of the specified string replaced.
   
  .Example
   ls *.log | Write-WtNewChar -old "%2F" -new "/"
   
   Replaces all occurrences of the escaped character with the original in all
   log files in the directory.
   
  .Example
   Write-WtNewChar -file WT_tx_id_found.txt -oldstring "`"`"" -newstring "`""
   
   Replaces all occurrences of doubled quotation marks with a single quotation mark.
   Output file is named 'WT_tx_id_found_fixed.txt'.
 #>
 
 	param(
		[parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[alias("Fullname")] 
		$file,
		[parameter(Mandatory=$true)]
		[alias("old")] 
		$oldstring,
		[parameter(Mandatory=$true)][alias("new")] 
		$newstring
	)
	$outfile = gci $file;
 	$out = Join-Path ($outfile).DirectoryName (($outfile).Basename + "_fixed" + ($outfile).Extension);
	(gc $file) -replace $oldstring, $newstring | sc $out;
 }

function Get-wtFileSizeSum{
    param (
            [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [alias("Length")]
            [alias("b")]
            [double]
            $bytes,
            [parameter(Mandatory=$false)]
            [alias("p")]
            $precision = '0')
    begin {
            [long]$sum = 0;
            $byteHash = @{"Bytes"=@();"KB"=@();"MB"=@();"GB"=@();"TB"=@()}; 
            $byteString = "";
        }
     process{
            $sum += $bytes;
  
    }
    end { 
            foreach ($size in ("Bytes","KB","MB","GB","TB")) 
        {
            if (($bytes -lt 1000) -or ($size -eq "TB"))
            {
                $format = "F0" + "$precision";
                if($input -ne $null){
                    $byteHash[$size] += ($bytes).ToString($format);
                } else {
                    $byteString = ($bytes).ToString($format) + " $size";
                }
                break;
                
            }
            else {
                $bytes /= 1KB
                  
            }
        }
            
    }
}

function Format-wtFileSize {

<#
 .Synopsis
  Takes an input number of bytes and returns its size in KB, MB, GB, or TB.

 .Description
  The input number is converted to its largest available measurement.  The
  optional parameter 'precision' sets the decimal precision of the returned
  value.  The default is zero, which will cause the returned value to be the
  floor or ceiling of the implicit decimal.  e.g., 3.9KB will appear as 4KB.
  This function will take any pipelined object that has a 'Length' property.

 .Parameter Bytes
  A number to be translated.  This number is expected to be a double.

 .Parameter Precision
  The decimal precision.  Defaults to zero (0). The default will cause the 
  output to be rounded to its floor or ceiling, depending on its size as a
  double (e.g., 3.13 KB will round to 3 KB and 3.91 KB will round to 4 KB).

 .Outputs
  If a single number is input, the translation is printed to standard out.
  Used in a pipeline, a hash is returned with the sizes as keys and the 
  translated numbers in arrays as values.

 .Example
  Format-wtFileSize -b 3200

  Using the default precision of zero, writes '3 KB' to standard out.

 .Example
  ls *.log | Format-wtFileSize -p 2

  Returns a hash.  Precision of 2 to give sizes to the nearest one-hundredth.

 .Example
  (ls *.log | Format-wtFileSize -p 2)["kB"] | sort

  Captures the sizes of the log files in the directory in the hash and prints
  the sizes of files which are kilobytes in size, sorted in ascending order.

#>
    param (
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [alias("Length")]
        [alias("b")]
        [double]
        $bytes,
        [parameter(Mandatory=$false)]
        [alias("p")]
        $precision = '0')

    begin {
        $size = "";
        $byteHash = @{"Bytes"=@();"KB"=@();"MB"=@();"GB"=@();"TB"=@()}; 
        $byteString = "";
    }
    process{
        foreach ($size in ("Bytes","KB","MB","GB","TB")) 
        {
            if (($bytes -lt 1000) -or ($size -eq "TB"))
            {
                $format = "F0" + "$precision";
                if($input -ne $null){
                    $byteHash[$size] += ($bytes).ToString($format);
                } else {
                    $byteString = ($bytes).ToString($format) + " $size";
                }
                break;
                
            }
            else {
                $bytes /= 1KB
                  
            }
        }
    }
    
    end { 
        if($byteString -ne ""){
            return $byteString;
        } else {
            return $byteHash;
        }
    }
}

#endregion

#region Webtrends Software

function Start-WebTrends {

	param([parameter(Mandatory=$true,
	       HelpMessage="Enter one of 'ui','geo' or 'sched' to start the UI, GeoTrends or the Scheduler")]
		  [ValidatePattern("(ui)|(geo)|(sched)")]
          [Alias("s")]
		  [string]$svc
		 )
	
	begin {
	
		$wtsvc = Get-Service -DisplayName "*WebTrends*";

        if($wtsvc -eq $null){
            throw [System.InvalidOperationException] "No Webtrends services installed on this system.";
        }

		$wtui  =  $wtsvc | ?{$_.DisplayName -match "User Interface"};
		$wtgeo =  $wtsvc | ?{$_.DisplayName -match "GeoTrends"};
		$wtsched = $wtsvc | ?{$_.DisplayName -match "Scheduler Agent"};
		$wtflag = $null
		
	}
	
	process {
		
		switch (($svc).toLower()){
			"ui"
			{
				if ($wtui.Status -eq "Running"){
					Write-Host "The UI service already is running.";
				} else {
					Write-Host "Starting the WebTrends UI server ...";
					Start-Service wtui;
				}
				$wtflag = $wtui.DisplayName
			}
			"geo"
			{
				if ($wtgeo.Status -eq "Running"){
					Write-Host "The GeoTrends Server already is running.";
				} else {
					Write-Host "Starting GeoTrends Service...";
					Start-Service $wtgeo.Name;
				}
				$wtflag = $wtgeo.DisplayName
			}
			"scheduler"
			{
				if ($wtsched.Status -eq "Running"){
					Write-Host "The scheduler already is running.";
				} else {
					Write-Host "Starting the scheduler ... ";
					Start-Service $wtsched.Name;
				}
				$wtflag = $wtsched.DisplayName
			}
			
		} # end switch
	}
	end {
		("`nThe status of the service `'{0}`' is now {1}.`n" -f $wtflag, (Get-Service -DisplayName $wtflag).Status)
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
	

} # end function Start-WebTrends

function Stop-WebTrends {

	param([parameter(Mandatory=$true,
	       HelpMessage="Enter one of 'ui','geo' or 'sched' to stop the UI, GeoTrends or the Scheduler")]
		  [ValidatePattern("(ui)|(geo)|(sched)")] 
		  [string]$svc
		 )
	
	begin {
	
		$wtsvc = Get-Service -DisplayName "*WebTrends*";

        if($wtsvc -eq $null){
            throw [System.InvalidOperationException] "No Webtrends services installed on this system.";
        }

		$wtui  = $wtsvc | ?{$_.DisplayName -match "User Interface"};
		$wtgeo = $wtsvc | ?{$_.DisplayName -match "GeoTrends"};
		$wtsched = $wtsvc | ?{$_.DisplayName -match "Scheduler Agent"};
		$wtflag = $null
		
	}
	
	process {
		
		switch (($svc).toLower()){
			"ui"
			{
				if ($wtui.Status -eq "Stopped"){
					return "The UI service already is stopped.";
				} else {
					Write-Host "Stopping the UI services ...";
					Stop-Service $wtui.Name;
				}
				$wtflag = $wtui.DisplayName
			}
			"geo"
			{
				if ($wtgeo.Status -eq "Stopped"){
					Write-Host "The GeoTrends Server already is stopped.";
				} else {
					Write-Host "Stopping GeoTrends Service...";
					Stop-Service $wtgeo.Name;
				}
				$wtflag = $wtgeo.DisplayName
			}
			"sched"
			{
				if ($wtsched.Status -eq "Stopped"){
					Write-Host "The scheduler already is stopped.";
				} else {
					Write-Host "Stopping the scheduler ...";
					Stop-Service $wtsched.Name;
				}
				$wtflag = $wtsched.DisplayName
				
			}
			
		} # end switch
	}
	
	end {
		("`nThe status of the service `'{0}`' is now {1}.`n" -f $wtflag, (Get-Service -DisplayName $wtflag).Status)
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
} # end function Stop-WebTrends

function Restart-WebTrends {

	param([parameter(Mandatory=$true,
	       HelpMessage="Enter one of 'ui','geo' or 'sched' to restart the UI, GeoTrends or the Scheduler")]
		  [ValidatePattern("(ui)|(geo)|(sched)")] 
		  [string]$svc
		 )
	
	begin {	
		$wtsvc = Get-Service -DisplayName "*WebTrends*";

        if($wtsvc -eq $null){
            throw [System.InvalidOperationException] "No Webtrends services installed on this system.";
        }

		$wtui  = $wtsvc | ?{$_.DisplayName -match "User Interface"};
		$wtgeo = $wtsvc | ?{$_.DisplayName -match "GeoTrends"};
		$wtsched = $wtsvc | ?{$_.DisplayName -match "Scheduler Agent"};
		$wtflag = $null
		Write-Host "Restarting ... ";
	}
	
	process {
		switch (($svc).toLower()){
			"ui"
			{
				if ($wtui.Status -eq "Stopped"){
					Start-Service $wtui.Name;
				} else {
					Stop-Service $wtui.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtui.Name;
				}
				$wtflag = $wtui.DisplayName
			}
			"geo"
			{
				if ($wtgeo.Status -eq "Stopped"){
					Start-Service $wtgeo.Name;
				} else {
					Stop-Service $wtgeo.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtgeo.Name;
					
				}
				$wtflag = $wtgeo.DisplayName
			}
			"sched"
			{
				$wtSvcName=$wtsched.DisplayName;
				if ($wtsched.Status -eq "Stopped"){
					Start-Service $wtsched.Name;
				} else {
					Stop-Service $wtsched.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtsched.Name;
				}
				$wtflag = $wtsched.DisplayName
			}
			
		} # end switch	
	}
	
	end {
		("`nThe status of the service `'{0}`' is now {1}.`n" -f $wtflag, (Get-Service -DisplayName $wtflag).Status)
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
} # end function Restart-WebTrends

function Get-WebTrends {

	begin {
		$wtsvc = Get-Service -DisplayName "*WebTrends*";
        
        if($wtsvc -eq $null){
            throw [System.InvalidOperationException] "No Webtrends services installed on this system.";
        }
		
	}

	process {
		$svcHeader = [string]::Format("{0,-40}", "Service");
		$svcHeader += [string]::Format("{0,10}", "Status");
		$l = '-' * 50;
		Write-Host $svcHeader;
		Write-Host $l;
		foreach ($svc in $wtsvc){
			$svcStr = [string]::Format("{0,-40}", $svc.DisplayName);
			$svcStr += [string]::Format("{0,10}", $svc.Status);
			Write-Host $svcStr;
		}
	}
	
	end {
		$wtsvc = $null;
	}

} # end function Get-WebTrends

#endregion

#region Utilities

function Search-WlpFiles{

<#
 .Synopsis 
  Search a directory of .wlp files for a specified element and return its definitions.
 
 .Description
  The function takes as its argument the name of an element present in a .wlp
  file, e.g. includeurlrebuild.  It searches each .wlp file presented to it for
  this element and captures its value(s).  Captures are assembled into a 
  hashtable which includes the name of the profile, the wlp filename and the
  collected definitions for the specified element.  If the element has more than
  one value, they are collected as a single string.
  
 .Parameter Element
  The configuration element to be searched.  This should be exactly as it 
  appears in the .wlp file.
  
 .Parameter Account
  The name of the WebTrends account, e.g. "Coca-Cola".  This is for informational
  purposes.  It is used in the creation of the output filename and a header 
  line in the document.
  
 .Parameter Output
  An optional switch.  If specified, the function will write the collected data
  out to file in CSV before exiting.  Note that even if this parameter is 
  specified, the function still returns the object with the collected data.
  The output processing attempts to place the file intelligently.  It will 
  first look for a Documents folder in the %USERPROFILE% directory, then a  
  'My Documents' folder and finally, failing those, to write the file in the
  %USERPROFILE% directory.
 
 .Outputs
  Returns an object with the following properties:  Account (name of the 
  account being worked with); Element (the configuration element being searched
  in the .wlp files); Extracts (the values found for the element); Matches 
  (number of matches found); and Files (number of .wlp files processed).
  
 .Notes 
  The Matches property represents the number of matches for which a hashtable 
  was created and attached to the data object.  It could happen than Matches
  is less than the number of files in the directory.  It could also happen
  that Matches is some multiple of Files, if the .wlp file contains more than
  one matching line item.
  For convenience, the object contains the Files property, which gives the 
  total number of .wlp files in the directory.  If Matches is less than Files, 
  this means that the element was not found in the "missing" files or that 
  the expression to match for values has a bug.  
  Extracts property is an array of hashtables.  Each hashtable represents
  one file processed.  Each hashtable has the following keys:  wlp (the file
  name); Name (the name of the profile, extracted from the wlp file); and 
  Definitions (the value or values of the element).  The value of a definition
  may be null (empty string), in which case an empty field will appear in the
  output.  If an element contains multiple values (e.g., content groups), the
  values are returned as a single string.
  The function will find every occurrence of the given string in the .wlp
  file.  For example, if you specify 'logdatasources' and there are multiple
  servers configured, the return data will reference each server's 
  'logdatasources' line.
#>

	param(
		[parameter(Mandatory=$true)] [string] $Element, 
		[string] $Account,
		[switch] $Output
		)

	begin {
		if (-not(Test-Path *.wlp)){
			Write-Host "No .wlp files found."
			return
		}
		$pattern = "$Element ?= ?(.*)" 
		
		$wlp = "" | Select-Object Account,Element,Extracts,Matches,Files
		$wlp.Extracts = @()
		$wlp.Element = $Element
		if ($Account){
			$wlp.Account = $Account
		} else {
			$wlp.Account = "WebTrends"
		}
		$wlp.Matches = 0
		$wlp.Files = (gci -Path "*.wlp").Count
	}
	process {
		Select-String -Path "*.wlp" -Pattern $pattern |
		Foreach-Object{
			$ele = @{}
			$current = $_.Filename
			$ele["Definitions"] = $_.Matches[0].Groups[1].Value
			$name = (Select-String -Path $_.Filename -Pattern "description ?= ?(.+)").Matches[0].Groups[1].Value
			$ele["wlp"] = $current
			$ele["Name"] = $name
			$wlp.Extracts += $ele
			$wlp.Matches++
		 }
	}
	end {
		if($Output){
			$outpath = ""
			$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
			$outfile = ("{0}_{1}_{2}.csv" -f $wlp.Account,$Element,$datestamp)
			if (Test-Path $env:USERPROFILE\Documents){
				$outpath = Join-Path -Path $env:USERPROFILE\Documents -ChildPath $outfile
			} elseif(Test-Path $env:USERPROFILE\My` Documents){
				$outpath = Join-Path -Path $env:USERPROFILE\Documents -ChildPath $outfile
			} else {
				$outpath = Join-Path -Path $env:USERPROFILE -ChildPath $outfile
			}
			Write-Host ("Output file was written to {0}" -f $outpath)
			Set-Content -Path $outpath -Value ("Account: {0},Date: {1},{2} Files Processed" -f $wlp.Account,(Get-Date -Format g), $wlp.Matches)
			Add-Content -Path $outpath -Value ("wlp Filename,Profile Name,{0} Definition" -f $wlp.Element)
			
			$wlp.Extracts | Foreach-Object{
			Add-Content -Path $outpath -Value ("{0},{1},{2}" -f $_.wlp,$_.Name,$_.Definitions)
			}
			
		}
		return $wlp
	}
}

function Get-ReplayDate{
<#
 .Synopsis
  Returns the date 90 days prior to the current date.
  
 .Description
  A WebTrends replay has to be requested for a date exactly 90 days prior 
  to the request date.  This function just provides that arithmetic.
#>
	$today = Get-Date
	return $today.AddDays(-90)
}

function Show-WtErrorDetail{
<#
 .Synopsis
  Displays information about an error stored in the error object.
  
 .Description
  The error object is an ArrayList that contains detailed information about all
  the errors that occur during a session. By default, this function displays the
  exception message and the invocation information about the last error that
  occurred.  However, you can pass into it a different error, e.g. $error[1].
#>
	param(
		$errorRecord = $Error[0]
	)
	if ($errorRecord -eq $null){
		throw [System.InvalidOperationException] "There is no error recorded until now.";
	}
	Write-Host ("Exception message is: `n {0}`n" -f $errorRecord.Exception);
	Write-Host("Invocation information is: `n");
	$errorRecord.InvocationInfo | Format-List *;
}


#endregion


# ------------------------ end Module Functions ---------------------
# -------------------------------------------------------------------

# ------------------------ Global Variables -------------------------

Set-Variable -Name dNFramework -Value (Get-FrameworkVersion) -Scope "Global" -Description "WebTrends Module Variable"
Set-Variable -Name WMVersion -Value (Get-ModuleVersion) -Scope "Global" -Description "WebTrends Module Variable"
Set-Variable -Name OSName -Value ( (Get-WmiObject Win32_OperatingSystem -computer "." | select Caption).Caption) `
-Scope "Global" -Description "WebTrends Module Variable"

# -----------------------------------------------------------------------
# Cmdlet aliases
# -----------------------------------------------------------------------
Set-Alias fws   Find-WtString   -Description "WebTrends Module alias"
Set-Alias gll	Get-LogLines	-Description "WebTrends Module alias"
Set-Alias bul	Backup-WtLogs	-Description "WebTrends Module alias"
Set-Alias gfv	Get-FrameworkVersion	-Description "WebTrends Module alias"
Set-Alias tfv	Test-FrameworkVersion 	-Description "WebTrends Module alias"
Set-Alias gpv	Get-PSVersion	-Description "WebTrends Module alias"
Set-Alias tpv	Test-PSVersion	-Description "WebTrends Module alias"
Set-Alias rwf	Rename-WtFiles 	-Description "WebTrends Module alias"
Set-Alias tpcx	Test-Pscx	-Description "WebTrends Module alias"
Set-Alias ginfo	Get-OSInfo 	-Description "WebTrends Module alias"
Set-Alias swlp 	Search-WlpFiles	-Description "WebTrends Module Alias"
Set-Alias grd	Get-wtRestData -Description "WebTrends Module Alias"
Set-Alias srh	Set-wtRestHash -Description "WebTrends Module Alias"
Set-Alias sawt	Start-WebTrends -Description "WebTrends Module Alias"
Set-Alias sowt	Stop-WebTrends -Description "WebTrends Module Alias"
Set-Alias rwt	Restart-WebTrends -Description "WebTrends Module Alias"
Set-Alias gwt 	Get-WebTrends -Description "WebTrends Module Alias"
Set-Alias rpd	Get-ReplayDate	-Description "WebTrends Module Alias"
Set-Alias cas	ConvertTo-WtAsciiSeparator	-Description "WebTrends Module Alias"
Set-Alias gwq	Get-WtUrlQuery	-Description "WebTrends Module Alias"
Set-Alias wnc	Write-WtNewChar -Description "Webtrends Module Alias"
Set-Alias ffs   Format-wtFileSize -Description "Webtrends Module Alias"
Set-Alias tdt   Test-wtTransDateTime -Description "Webtrends Module Alias"

Export-ModuleMember `
-Alias * `
-Cmdlet * `
-Variable * `
-Function "Backup-WtLogs", "Find-WtString", "Find-WtQueryStringPair", "Get-FrameworkVersion", "Get-WtModuleInfo", `
		  "Get-LogLines", "Get-PSVersion", "Rename-WtFiles", "Test-FrameworkVersion", "Test-PSVersion", "Get-OSInfo", `
		  "Test-Pscx", "Search-WlpFiles", "Get-wtRestData", "Set-wtRestHash", "ConvertTo-WtAsciiSeparator", "Get-WtUrlQuery", `
		  "Start-WebTrends", "Stop-WebTrends", "Restart-WebTrends", "Get-WebTrends", "Get-ReplayDate", `
		  "ConvertTo-WtCsv", "Write-WtNewChar", "Format-wtFileSize", "Test-wtTransDateTime", "Find-wtQuery"