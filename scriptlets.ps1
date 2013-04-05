# $Id: scriptlets.ps1,v 1.1 2012/03/28 12:47:06 powem Exp $

$build = @{n="Build";e={$_.BuildNumber}}
$SPNumber = @{n="SPNumber";e={$_.CSDVersion}}
$sku = @{n="SKU";e={$_.OperatingSystemSKU}}
$hostname = @{n="HostName";e={$_.CSName}}

$Win32_OS = Get-WmiObject Win32_OperatingSystem -computer "." | select $build,$SPNumber,Caption,$sku,$hostname, servicepackmajorversion

# matches using named captures
$content |?{$_ -match $patt}|%{$matches['digit']}

$computer = "LocalHost" 
$namespace = "root\CIMV2" 
Get-WmiObject -class Win32_SystemUsers -computername "." -namespace $namespace

$computer = "LocalHost" 
$namespace = "root\CIMV2" 
Get-WmiObject -class Win32_UserAccount -computername $computer -namespace $namespace

([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups | Foreach-Object { $_.Translate([System.Security.Principal.NTAccount])}

([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups | ?{ $_.Translate([System.Security.Principal.NTAccount]).ToString() -match "BUILTIN"} | %{$_.Translate([System.Security.Principal.NTAccount])}


# dummy up a log file with traffic source parameters
# hash consists of elements from a referrer and a corresponding value
# for WT.tsrc to be added to the query string.
$sources = @{"playstation.com/search-results" = "WT.tsrc=Internal%20-%20Search";
"google" = "WT.tsrc=Search%20-%20Google";
"yahoo" = "WT.tsrc=Search%20-%20Yahoo";
"bing" = "WT.tsrc=Search%20-%20Bing";
"facebook" = "WT.tsrc=Social%20Media%20-%20Facebook";
"search.aol.com" = "WT.tsrc=Search%20-%20AOL";
"blog.eu.playstation.com" = "WT.tsrc=Internal%20-%20Blog";
"blog.us.playstation.com" = "WT.tsrc=Internal%20-%20Blog";
"community.eu.playstation.com" = "WT.tsrc=Internal%20-%20Communities";
"newsletters.eu.playstation.com" = "WT.tsrc=Internal%20-%20Newsletters"
}

$content = gc $logfilename

# shortcut to read the contents of a file for processing
# file in the current directory, on the c: drive
${c:dcsd6yf4qe9xjycw05rz0tnoc_8g3z-dcs-2011-11-22-00-0000-0009-1321921519-pdxsplit04_sp1.log}

# file in the given directory, c:\logs
${c:\logs\dcsd6yf4qe9xjycw05rz0tnoc_8g3z-dcs-2011-11-22-00-0000-0009-1321921519-pdxsplit04_sp1.log}

# extract the referrers via the SDC regex
# key is the referrer and value is a count of its occurrences
# useful for determining how to set up the $sources 
$content |?{$_ -match $env:sdcregex}|%{$refs[$matches['referrer']]++}

# process the file contents and alter the query string to prepend the WT.tsrc
# parameter as needed.
$content | ?{$_ -match $env:sdcregex}| %{foreach ($s in $sources.keys){	if (($matches.referrer).Contains($s)){$_ = $_ -replace $matches.query,($sources[$s]+'&'+$matches.query); break;} } ac -Value $_ -Path "$env:logs\sony_eu\newlog.log"} 

$content | Where-Object {$_ -match $env:sdcregex}|
ForEach-Object {
	foreach ($s in $sources.keys){
		if (($matches.referrer).Contains($s)){
				$_ = $_ -replace $matches.query,($sources[$s]+'&'+$matches.query)
				break;
			} 
	}
	Add-Content -Value $_ -Path "$env:logs\sony_eu\newlog.log"
} 

function ConvertTo-WtTrafficSourcesDemoLog{

<#
 .Synopsis
  Convert a log file to a demo log by adding a parameter to the query string field.
  
 .Description
  Uses a hashtable to add parameter to the query string field in an SDC log, based
  on values in the referrer.  The origin of this function was the requirement to produce
  a demo of a customized version of the Traffic Sources report, based on the contents 
  of the referrer.
  
 .Parameter Infile
  The file to be converted
  
 .Parameter Outfile
  The file to write as the conversion.
  
 .Parameter Modifiers
  A hashtable consisting of strings to match in the referrer for the keys, and the
  values of the parameter to insert into the query string.  The values field should
  include the name of the parameter.  The format is <parameter>=<parameter value>,
  e.g., WT.tsrc=Google.
  
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
  
#>

	param([string] $infile,[string] $outfile, [hashtable] $modifiers)
	
	$content = Get-Content $infile
	
	[string] $regex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]"
	 
	$content | Where-Object {$_ -match $regex}|
	ForEach-Object {
		foreach ($s in $modifiers.keys){
			if (($matches.referrer).Contains($s)){
					$_ = $_ -replace $matches.query,($modifiers[$s]+'&'+$matches.query)
					break;
				} 
		}
		Add-Content -Value $_ -Path "$outfile"
	}
}

function Get-Shortcut {
	$obj = New-Object -ComObject WScript.Shell
	$pathUser = [System.Environment]::GetFolderPath('StartMenu')
	$pathCommon = $obj.SpecialFolders.Item('AllUsersStartMenu')
	dir $pathUser, $pathCommon -Filter *.lnk -Recurse |
	ForEach-Object {
		$link = $obj.CreateShortcut($_.FullName)

		$info = @{}
		$info.Hotkey = $link.Hotkey
		$info.TargetPath = $link.TargetPath
		$info.LinkPath = $link.FullName
		$info.Arguments = $link.Arguments
		$info.Target = try {Split-Path $info.TargetPath -Leaf } catch { 'n/a'}
		$info.Link = try { Split-Path $info.LinkPath -Leaf } catch { 'n/a'}
		$info.WindowStyle = $link.WindowStyle
		$info.IconLocation = $link.IconLocation

		New-Object PSObject -Property $info
	}
}

function Rename-WtFiles {
	$path = "c:\Users\powem\Documents\clients\zinio\translationfiles\updated"
	$destination = "c:\Users\powem\Documents\clients\zinio\translationfiles"
	cd $path
	gci | %{
		if ($_.Name.Contains("_Categories")){
			Rename-Item -Path $_.Name -NewName "Categories.csv"
			Move-Item -Path "Categories.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_Excerpts")){
			Rename-Item -Path $_.Name -NewName "Excerpts.csv"
			Move-Item -Path "Excerpts.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_Issues")){
			Rename-Item -Path $_.Name -NewName "Issues.csv"
			Move-Item -Path "Issues.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_Newsstands.csv")){
			Rename-Item -Path $_.Name -NewName "Newsstands.csv"
			Move-Item -Path "Newsstands.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_publications")){
			Rename-Item -Path $_.Name -NewName "publications.csv"
			Move-Item -Path "publications.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_Publishers.csv")){
			Rename-Item -Path $_.Name -NewName "Publishers.csv"
			Move-Item -Path "Publishers.csv" -Destination $destination -Force
		} elseif($_.Name.Contains("_Publishers_New.csv")){
			Rename-Item -Path $_.Name -NewName "Publishers_New.csv"
			Move-Item -Path "Publishers_New.csv" -Destination $destination -Force
		} else {
			Write-Host "Finished renaming and moving files."
		}
	}
	
	cd $destination
	Compress-RarFile
}

function Compress-RarFile{

<#
 .Synopsis
  Pack all the specified files into a RAR file.

#>

	param( $ext = "*.csv")
	
	if(-not($env:Path.Contains("RAR"))){
		Write-Host "WinRAR not found in path."
		Write-Host "WinRAR must be in the path to use this function."
		return
	}
	
	if(Test-Path "translationfiles.rar.bak"){
		Remove-Item -Path "translationfiles.rar.bak"
	}
	
	if(Test-Path "translationfiles.rar"){
		Rename-Item -Path "translationfiles.rar" -NewName "translationfiles.rar.bak"
	}
	
	Invoke-Expression -Command "rar a translationfiles.rar $ext"	
}

function Get-WtQuery{

<#
 .Synopsis
  Processes a given set of log files and retrieves the query strings.
  
 .Description
  Retrieves the query strings as an array with the URI stem as the key pointing to
  the array.  The arrays are deduplicated.  The {URI,query} hashtables are properties
  of a WebTrends file object which contains the name of the log file and its full 
  path.  These individual file objects are collected in a comprehensive object as an
  array.  The comprehensive object is returned.
  
  By default, the function processes *.log in a directory.  Optionally, a single log
  file may be passed on on the function call.  

#>

	param( $name="WebTrends", $type = "WTOD", $log = "*.log" )
	
	$sdcregex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"
	$wtqueries = @()
	$wturi = @()
	$wturiqry = @{}
	$wtfile = "" | Select-Object Name,Query,Uri,Path
	$wt = "" | Select-Object Name,Files,Type
	$wt.Files = @()
	$wt.Name = $name
	$wt.Type = $type
	
	gci $log | 
	ForEach-Object{
		$wtfile = "" | Select-Object Name,Query,Uri,Path
		$wtfile.Name = $_.Name
		$wtfile.Path = $_.FullName
		$content = gc $_.FullName
		$content | ?{-not($_.StartsWith('#')) -and $_ -match $sdcregex} |
		ForEach-Object {
			if (-not($wturiqry.ContainsKey( $matches['uri']))){
				$wturiqry.Add($matches['uri'], @($matches['query']))
			} else {
				$wturiqry[$matches['uri']] += $matches['query']
				$wturiqry[$matches['uri']] = $wturiqry[$matches['uri']] | select -Unique
			}
		}
		$wtfile.Query = $wturiqry
		$wt.Files += $wtfile
	}
	return $wt
}

function Get-WtLogData{
<#
 .Synopsis
  Collect information about the URIs, query strings and referrers in a set of WebTrends SDC or WTOD logs
 .Description
  This function creates a WebTrends object that contains information about the log files being processed.
  The object collects the name and path of each file processed.  A hash is available consisting of the 
  URI for a key and an array of referrers for the URI; and a hash consisting of the URI for a key and an array of 
  query strings associated with the URI.  Finally, a simple array of the URIs is available.  
  
  The arrays are all deduplicated.
  
  Uaing this function, it is possible to find a given value in any of these fields and identify which log file
  that value appeared in.  It is also possible to pass the data through pipelines.
  
  .Parameter Name
   A name that can be used to identify the material in some way, possibly for use when exporting to a file.
   
  .Parameter Type
   A type that can be used to identify the source, e.g. "WTOD"
   
  .Parameter Log
   The log file to be examined.  Defaults to "*.log".
   
  .Outputs
   An object with properties consisting of the collected data.
  
#>


	param($name = "WebTrends",
		  $type = "WTOD",
		  $log  = "*.log")
			
	$sdcregex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"
	$wturi = @()
	$wturiref = @{}
	$wturiqry = @{}
	
	$wtfile = "" | Select-Object Name,Queries,Referrers,Uri,Path
	$wt = "" | Select-Object Name,Files,Type
	$wt.Files = @()
	$wt.Name = $name
	$wt.Type = $type
	
	gci $log | 
	ForEach-Object{
		$wtfile = "" | Select-Object Name,Queries,Referrers,Uri,Path
		$wtfile.Name = $_.Name
		$wtfile.Path = $_.FullName
		$content = gc $_.FullName
		$content | Where-Object{ -not($_.StartsWith('#')) -and $_ -match $sdcregex} |
		ForEach-Object {
			$wturi += $matches['uri']
			if (-not($wturiref.ContainsKey( $matches['uri']))){
				$wturiref.Add($matches['uri'], @($matches['referrer']))
			} else {
				$wturiref[$matches['uri']] += $matches['referrer']
				$wturiref[$matches['uri']] = $wturiref[$matches['uri']] | select -Unique
			}
			if (-not($wturiqry.ContainsKey( $matches['uri']))){
				$wturiqry.Add($matches['uri'], @($matches['query']))
			} else {
				$wturiqry[$matches['uri']] += $matches['query']
				$wturiqry[$matches['uri']] = $wturiqry[$matches['uri']] | select -Unique
			}
		}
		$wturi = $wturi | select -Unique
		$wtfile.Uri = $wturi
		$wtfile.Queries = $wturiqry
		$wtfile.Referrers = $wturiref
		$wturi = @()
		$wturiqry = @{}
		$wturiref = @{}
		$wt.Files += $wtfile
	}
	return $wt
}

function Split-WtQuery {

	param ([array] $queries)
	
	if (-not($queries) -or -not($queries.GetType().Name -eq "Object[]")){
		Write-Host "Need an array of query strings."
		return
	}
	
	$items = @()
	$params = @()
	$values = @()
	
	$wtqry = "" | Select-Object Line,Items,Parameters,Values
	$wtqueries = "" | Select-Object Query,Count
	
	$wtqueries.Count = 0
	$wtqueries.Query = @()
	
	foreach($q in $queries){
		$wtqry.Line = $q
		$items = $q.split('&')
		foreach ($i in $items){
			$params += $i.split('=')[0]
			$values += $i.split('=')[1]
		}
		$wtqry.Items = $items
		$wtqry.Parameters = $params
		$wtqry.Values = $values
		$wtqueries.Query += $wtqry
		$wtqueries.Count++
		$params = @()
		$values = @()
	}
	return $wtqueries
}


function Send-WtMail{
	$server = "exchange.webtrends.corp"
	$ol = New-Object -comObject Outlook.Application 
	$mail = $ol.CreateItem(0) 
	$Mail.Recipients.Add("michael.powe@webtrends.com") 
	$Mail.Subject = "PS1 Script TestMail" 
	$Mail.Body = " 
	Test Mail 
	" 
	$Mail.Send() 

}

$restConfig = @{version="v3";
				profile="21897";
				report="hGgJLBjviR6";
				type="indv";
				totals="none";
				format="html";
				measures="measures=0*1*2";
				user="zinio\wt-mpowe";
				pass="Pa55w0rd@"}

function Get-RestData{

<#
 .Synopsis 
  Retrieve report data from WebTrends via REST.
 
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
  
  Some trivial exception handling is included, which may prevent falling into an infinite
  loop of errors if something goes wrong.
#>


	param (
	[parameter(Mandatory = $true)] [string]$Start,
	[parameter(Mandatory = $true)] [string]$End,
	[parameter(Mandatory = $true)] [hashtable]$Conf)
	
	$version = $Conf.version
	$profile = $Conf.profile
	$report = $Conf.report
	$type = $Conf.type
	$totals = $Conf.totals
	$format = $Conf.format
	# put in a nonsense number to include all measures
	$measures = $Conf.measures
	
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
	
	$Username = $Conf.user
	$Password = $Conf.pass
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
	
	if ($reader -ne $null){
		$reader.Close()
	}
	if ($response -ne $null){
		$response.Close()
	}
	
	return $restData
}

# trap [System.ArgumentOutOfRangeException] {"An argument range exception occurred: $_"; continue }
	# trap [System.ArgumentException] {"An argument exception occurred: $_"; continue }
#	while ($reader.Peek() -ge 0){
#		$buffer = @()
#		$responseHTML = $reader.Read($buffer,0,4096)
#		$restData.Count += $responseHTML.Length
#		if($responseHTML -ne $null){
#			$restData.Data += [system.string]::Join("",$responseHTML)
#		}
#		
#	}

	
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
  purposes and is used in the creation of the output filename.
  
 .Parameter Output
  An optional switch.  If specified, the function will write the collected data
  out to file in CSV before exiting.  Note that even if this parameter is 
  specified, the function still returns the object with the collected data.
  
 .Outputs
  Returns an object with the following properties:  Account (name of the 
  account being worked with); Element (the configuration element being searched
  in the .wlp files); Extracts (the values found for the element); and
  Count (number of files processed successfully).
  
  The Count property represents the number of files for which a hashtable was
  created and attached to the data object.  It could happen than Count is
  less than the number of files in the directory.  This means that the 
  element was not found in the "missing" files or that the expression to
  match for values has a bug.  

  Extracts property is an array of hashtables.  Each hashtable represents
  one file processed.  Each hashtable has the following keys:  wlp (the file
  name); Name (the name of the profile, extracted from the wlp file); and 
  Definitions (the value or values of the element).  The value of a definition
  may be null (empty string), in which case an empty field will appear in the
  output.  If an element contains multiple values (e.g., content groups), the
  values are returned as a single string.
#>

	param(
		[parameter(Mandatory=$true)] [string] $Element, 
		[string] $Account,
		[switch] $Output
		)

	if (-not(Test-Path *.wlp)){
		Write-Host "No .wlp files found."
		return
	}
	$pattern = "$Element ?= ?(.*)" 
	$wlp = "" | Select-Object Account,Element,Extracts,Count
	
	$wlp.Extracts = @()
	$wlp.Element = $Element
	if ($Account){
		$wlp.Account = $Account
	} else {
		$wlp.Account = "WebTrends"
	}
	$wlp.Count = 0
	Select-String -Path "*.wlp" -Pattern $pattern |
	%{
		$ele = @{}
		$current = $_.Filename
		$ele["Definitions"] = $_.Matches[0].Groups[1].Value
		$name = (Select-String -Path $_.Filename -Pattern "description ?= ?(.+)").Matches[0].Groups[1].Value
		$ele["wlp"] = $current
		$ele["Name"] = $name
		$wlp.Extracts += $ele
		$wlp.Count++
	 }
	
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
		Set-Content -Path $outpath -Value ("Account: {0},Date: {1},{2} Files Processed" -f $wlp.Account,(Get-Date -Format g), $wlp.Count)
		Add-Content -Path $outpath -Value ("wlp Filename,Profile Name,{0} Definition" -f $wlp.Element)
		
		$wlp.Extracts | %{
		Add-Content -Path $outpath -Value ("{0},{1},{2}" -f $_.wlp,$_.Name,$_.Definitions)
		}
		
	}
		return $wlp
}

function Convert-WtToCsv {

	param([parameter(Mandatory=$true)] [hashtable] $wt,
		  [parameter(Mandatory=$true)] [string] $element)
	
	Set-Content -Path "C:\Users\powem\Documents\clients\3M\urlrebuild.csv" -Value ("wlp Filename,Profile Name,{0} definition" -f $element)
	
	$wt | %{
		foreach($k in $wt.keys){
		
		Add-Content -Path "C:\Users\powem\Documents\clients\3M\urlrebuild.csv" -Value $line
		}
	}
}

function Get-SftpItems{

	param( [parameter(Mandatory=$true)] [string] $user,
		   [parameter(Mandatory=$true)] [string] $pass
		 )

$file = "c:\Users\powem\Documents\clients\zinio\sftp.txt"
$server = "sftp.webtrends.com"

$puser = "zinio\\wt-mpowe"

$login = "{0}@{1}" -f $user, $server

Invoke-Expression -Command ("'C:\Program Files (x86)\PuTTY\psftp.exe' '{0}' -pw {1} -b {2}" -f $login, $pass, $file)

}

# use named groups with select-string
$sdcregex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"
$captures = Select-String -Path *.log -Pattern $sdcregex
$captures | select -ExpandProperty Matches | %{$_.groups["query"].value}


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
#>

	param([parameter(Mandatory=$false,
					 HelpMessage="Specify the URL parameter to be matched.")] $parameter = "nit_g_market",
		  [parameter(Mandatory=$false,
		  			 HelpMessage="Specify a regular expression to match the parameter value, that includes a named capture group")] $value = "(?<value>sw[^&]+)"	
		 )

	begin {
		$regex = "[^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<host>[^ ]+) [^ ]+ (?<uri>[^ ]+) (?<query>[^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ (?<referrer>[^ ]+) [^ ]+"
		$collect = @{}
		$urls = @()
		$counter = 0
	}
	
	process {
		gci *.log | Select-String -Pattern $regex |  select -ExpandProperty Matches | %{
			if ($_.groups["query"].value -match ("{0}={1}" -f $parameter, $value)){
				if ($collect.keys -contains $matches.value ) {
					$collect[$matches.value] += $_.groups["uri"].value
				} else {
					$collect[$matches.value] = @($_.groups["uri"].value)
				}	
			}
			if (($counter++ % 1000) -eq 0){
				Write-Host ("Processed {0} lines" -f ($counter-1))
			}
		}
		$collect.sweden = $collect.sweden | select -Unique
		$collect.switzerland = $collect.switzerland | select -Unique
	}
	
	end {
		return $collect
	}
}

# date time cs-ip cs-method cs-uri sc-status sc-bytes time-taken cs(Referer) cs(User-Agent) cs(Cookie)
# nestle server log

function Get-LogStatistics {

	begin {
		[string] $nestleregex = "^\d{4}-\d{2}-\d{2}[ \t]+\d{2}:\d{2}:\d{2}[ \t]+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}[ \t]+.*[ \t]+(?<uri>[^ ]+)[ \t]+[^ ]+[ \t]+[^ ]+[ \t]+[^ ]+[ \t]+`"(?<referrer>.*)`"[ \t]+`"(?<agent>.*)`"[ \t]+[^ ]+$"

	}
	process {
	
	
	}
	
	end {
	
	}
}



function ConvertTo-WtCsv {

	param(
			[parameter(Mandatory=$true,
					  HelpMessage="A hashtable that will be enumerated and written out to csv.")] [hashtable] $hash
		 )
						

	begin {}
	
	process {
		$hash.GetEnumerator() | 
     		Foreach {$obj = new-object psobject `
			-prop @{col1=$_.Name}; $_.Value | Foreach {$i=2} {Add-Member NoteProperty "col$i" $_ -Inp $obj; $i++} {$obj} } | 
     		Sort {$_.psobject.properties.count} -desc | ConvertTo-Csv -NoTypeInformation
	}
	
	end {}

}

$wt.Collect.GetEnumerator() | 
     Foreach {$obj = new-object psobject -prop @{col1=$_.Name}; $_.Value | 
        Foreach {$i=2} `
                {Add-Member NoteProperty "col$i" $_ -Inp $obj; $i++} {$obj} } | 
     Sort {$_.psobject.properties.count} -desc | ConvertTo-Csv -NoTypeInformation


$wt.Collect.Keys | %{$a = $wt.Collect[$_];
	for($i = 0; $i -lt $a.length; $i++){
		$a[$i] = $_+","+$a[$i];
	}
	$str += [System.String]::Join("`n",$a);
	}


#[logdatasrc784]
#logfilecount = 2
#profileversion = 1
#wlpid = qe6mKDHsIQ6
#logfileformat = 0
#logdatasrctype = logfile
#profileid = r0pHznxgMW6
#profilename = Data Source 784
#logfilepath0 = D:\wrs\modules\analysis\logfiles\qe6mKDHsIQ6\pdxsplit04_sp1\dcsh9bdkrvz5bdiei93o0f8gm_4k7r-*.log.gz.lnk
#logfilepath1 = D:\wrs\modules\analysis\logfiles\qe6mKDHsIQ6\pdxsplit04_sp1\dcsqflkafuz5bda06ogtjv1uo_7k3m-*.log.gz.lnk
#username = 
#sourcecontenttype = 
#password = 


function Find-wtDatasources(){
	
	begin{
		
		$ini = @()
		$file = "default.ini"
		$re = ".*(?<dcsid>dcs[^_]+_[a-z0-9]{4})"
	}
	
	process{
		$d = Get-Content $file
		for($i = 0; $i -lt $d.length; $i++){
			if ($d[$i].StartsWith("[")){
				$lds = "" | Select-Object name, wlpid, profileid, profilename, dcsid
				$lds.Name = $d[$i].Substring(1,$d[$i].length-1)
			} elseif ($d[$i].StartsWith("wlpid")){
				$lds.Wlpid = ($d[$i]).split('=')[1].Trim()
			} elseif ($d[$i].StartsWith("profileid")){
				$lds.Profileid = ($d[$i]).split('=')[1].Trim()
			} elseif ($d[$i].StartsWith("profilename")){
				$lds.profilename = ($d[$i]).split('=')[1].Trim()
			} elseif ($d[$i].StartsWith("logfilepath")){
			
			}
		
		}
	
	
	}
	
	end{
	
	}



}

function get-epochdate ($epochdate) { 
	[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochdate)) 
}
get-epochdate 1295113860

function Add-SessionVariable()
{
        param ([string[]]$VariableName=$null)
       
        [string[]]$VariableNames = [AppDomain]::CurrentDomain.GetData('Variable')
        $VariableNames += $VariableName
       
        if ($input)
        {
                $VariableNames += $input
        }
       
        #To Not Waste Space, Remove Duplicates
        $VariableNames = $VariableNames | Select-Object -Unique
       
        [AppDomain]::CurrentDomain.SetData('Variable',$VariableNames)
}
 
function Set-SessionVariableList()
{
        $VariableNames = Get-Variable -scope global| ForEach-Object {$_.Name}
        Add-SessionVariable $VariableNames
       
        Write-Verbose 'Loaded Variable Names into AppDomain'
        $counter = 1
        Foreach ($Variable in $VariableNames)
        {
                Write-Verbose "`t $($counter): $Variable"
                $counter++
        }
}
 
function Get-SessionVariableList()
{
        [AppDomain]::CurrentDomain.GetData('Variable')
}
 
function Remove-NewVariable()
{
        $StartingMemory = (Get-Process -ID $PID).WS / 1MB
        Write-Verbose "Current Memory Usage: $StartingMemory MB"
 
        $VariableNames = Get-SessionVariableList
        $VariableNames += 'StartingMemory'
        Get-Variable -scope global | Where-Object {$VariableNames -notcontains $_.name} | Remove-Variable -scope global
       
        [GC]::Collect()
       
        $EndingMemory = (Get-Process -ID $PID).WS / 1MB
        Write-Verbose "Ending Memory: $EndingMemory MB"
       
        $Diff = $StartingMemory - $EndingMemory
        Write-Verbose "Freed up: $Diff MB"
}

gci -Filter *.log | Select-String -Pattern $searcher | %{$wtmatches[$_.Matches[0].Groups[1].Value]++; $items++;

$wtmatches = @{};
gci -Filter *.log | Select-String -Pattern $searcher | %{ $wtmatches[$_.Matches[0].Groups[1].Value]++; $items++; [GC]::Collect(); }
						 

				 
function ProcessFile
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

#$results = dir *.log | ProcessFile -Pattern 'stuff (capturegroup)' -Group 1
#"Total matches: $($results.TotalCount)"
#$results.Unique | Out-File .\Results.txt

    Function Add-SessionVariable()
    {
            param ([string[]]$VariableName=$null)
           
            [string[]]$VariableNames = [AppDomain]::CurrentDomain.GetData('Variable')
            $VariableNames += $VariableName
           
            if ($input)
            {
                    $VariableNames += $input
            }
           
            #To Not Waste Space, Remove Duplicates
            $VariableNames = $VariableNames | Select-Object -Unique
           
            [AppDomain]::CurrentDomain.SetData('Variable',$VariableNames)
    }
     
    Function Set-SessionVariableList()
    {
            $VariableNames = Get-Variable -scope global| ForEach-Object {$_.Name}
            Add-SessionVariable $VariableNames
           
            Write-Verbose 'Loaded Variable Names into AppDomain'
            $counter = 1
            Foreach ($Variable in $VariableNames)
            {
                    Write-Verbose "`t $($counter): $Variable"
                    $counter++
            }
    }
     
    Function Get-SessionVariableList()
    {
            [AppDomain]::CurrentDomain.GetData('Variable')
    }
     
    Function Remove-NewVariable()
    {
            $StartingMemory = (Get-Process -ID $PID).WS / 1MB
            Write-Verbose "Current Memory Usage: $StartingMemory MB"
     
            $VariableNames = Get-SessionVariableList
            $VariableNames += 'StartingMemory'
            Get-Variable -scope global | Where-Object {$VariableNames -notcontains $_.name} | Remove-Variable -scope global
           
            [GC]::Collect()
           
            $EndingMemory = (Get-Process -ID $PID).WS / 1MB
            Write-Verbose "Ending Memory: $EndingMemory MB"
           
            $Diff = $StartingMemory - $EndingMemory
            Write-Verbose "Freed up: $Diff MB"
    }
}

$ht = @{user1=,'Group2';user2='Group1','Group2','Group3';
            user3='Group3','Group4'}

$ht.GetEnumerator() | 
     Foreach {
     	$obj = new-object psobject -prop @{col1=$_.Name}; $_.Value | 
        Foreach {$i=2} {Add-Member NoteProperty "col$i" $_ -Inp $obj; $i++} {$obj} } | 
     	Sort {$_.psobject.properties.count} -desc | 
		ConvertTo-Csv -NoTypeInformation
	 
	 
	# how to load an assembly
	[Reflection.Assembly]::LoadFrom("C:\Windows\Assembly\Gac\Microsoft.Office.Interop.Outlook\12.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Outlook.dll")
$q = New-Object System.Collections.Generic.Queue[String] (,[string[]]$str.Split(" "));
$newstr = ""; while($newstr.length -lt 30){$newstr += $q.deQueue()+" "}

# get named captures from a file or set of lines
$content |?{$_ -match $patt}|%{$matches['digit']}


function Get-NamedMatches{

	param(
		[Parameter(Mandatory = $true,Position=0)] 
		[ValidateScript({Test-Path $_})]
		[string] $FilePath,
		[Parameter(Mandatory = $true,Position=1)] 
		[ValidateScript({$_ -match "\?<[a-zA-Z]+>"})]
		[string] $Pattern,
		[Parameter(Mandatory = $true,Position=2)] [string] $Name,
		[Parameter(Mandatory = $false,Position=3)] [switch] $Write
	)

	begin{
		$input = Get-Content $FilePath;
		$content = $null;
	}
	
	
	process{
	
		$content = ($input | ?{$_ -match $Pattern}| %{$matches["$Name"]});
		if($Write){
			$fname = $name + "_found.log";
			Out-File -FilePath ("$env:USERPROFILE\Desktop\" + $fname);
		} else {
			$content;
		}
	
	}
	
	
	end{}

}


$orders | %{for($i=0; $i -lt $_.url.length; $i++){$data[$i] = $_.date[$i]+","+$_.time[$i]+","+$_.user[$i]+","+$_.url[$i]+","+$_.file[$i]} }

 $orders | %{for($i=0; $i -lt $_.url.length; $i++){$l = ($_.date[$i]+","+$_.time[$i]+","+$_.user[$i]+","+$_.url[$i]+","+$_.file[$i]); $data += $l; } }
 
 $a | %{$line = $_.Line.Split(); $orders.url += $line[6]; $orders.file += $_.Filename; $orders.date += $line[0]; $orders.user += $line[2]; $orders.time += $line[1]; }
 

 function Test-wtTrans {
 
 	begin {
		$invoice = "WT.tx_i=(?<inv>[^ &]+)";
		$invdate = "WT.tx_id=(?<dt>[^ &]+)";
		$invtime = "WT.tx_it=(?<tm>[^ &]+)";
		$sub = "WT.tx_s=(?<sub>[^ &]+)";
		$units = "WT.tx_u=(?<un>[^ &]+)";
		$sku = "WT.pn_sku=(?<sk>[^ &]+)";
		$event = "WT.tx_e=(?<ev>[^ &]+)";
		
		# regular expressions for matching
		# invoice is any character/digit string
		$txi   = "WT.tx_i=(?<invoice>[^&]+&)"
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

 		$transactions = New-Object psobject -Property @{inv=@();date=@();time=@();subtotal=@();units=@();sku=@();event=@();cline=@{}};
 
		$f = gci *.log
		$lines = @();
 
 	}
 	process{
 		$f | %{ switch -regex -file $_.Fullname {
 
		$invoice {$transactions.inv += $matches['inv'];}
		$invdate {$transactions.date += $matches['dt'];  }
		$invtime {$transactions.time += $matches['tm'];  }
		$units {$transactions.units += $matches['un'];  }
		$sub {$transactions.subtotal += $matches['sub'];  }
		$sku {$transactions.sku += $matches['sk'];  }
		$event {$transactions.event += $matches['ev'];  }
	
 		}
 	}
  
		for ($i=0; $i -lt $transactions.date.Length; $i++){
		 
		 	if ($transactions.date[$i] -match $txid){
				$transactions.date[$i] = 0;
			} else {
				$transactions.date[$i] = ($transactions.date[$i] -replace "%2F","/");
			}
		}
		for ($i=0; $i -lt $transactions.time.Length; $i++){
		 
		 	if ($transactions.time[$i] -match $txit){
				$transactions.time[$i] = 0;
			} else {
				$transactions.time[$i] = ($transactions[$i] -replace "%3A",":");
			}
		}
		 for ($i=0; $i -lt $transactions.subtotal.Length; $i++){
		 
		 	if ($transactions.subtotal[$i] -match $txs){
				$transactions.subtotal[$i] = 0;
			}
		}
 
 	}
 
 	end {
		 $transactions.date = $transactions.date | Sort-Object -Unique;
		 $transactions.time = $transactions.time | Sort-Object -Unique;
		 $transactions.subtotal = $transactions.subtotal | Sort-Object -Unique;
 	}
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


function Find-wtQueryMultiple{

    param(
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [alias("Fullname")]
        $file,
        [parameter(Mandatory=$true)]
        [alias("a")]
        [object[]]$array,
        [parameter(Mandatory=$true)]
        [alias("p")]
        [string]$parameter
    )
    begin{
        $found = New-Object -TypeName psobject -Property @{Param=""; Ids=@(); Lines=@()}
        $found.Ids = $array;
        $found.Param = $parameter;
    }
    process{
        Get-ChildItem $file |
        ForEach-Object{
            foreach ($id in $ids){ 
                sls -Path $_.Fullname -Pattern "WT.vtid=$id"
            }
        } | 
        ForEach-Object{ $found.lines += $_.Line; }
    }
    end{}


}

$ids = "225debf59f7443bb67ec101349188771","22740c349332f900d3074e1341819659","24b337ddb7c06ad90ef5791340643434","25b10125e8ad06529e9b391349060550","25cb141f6c8751ce7de3321347554427","2644be5b17da733013dbd81343252510","26480419e15819d08ab46c1343596325","265db1b0823292235aeeda1323147929","26da264a823cf66413a0941343454052","274a55dc9bbb84732edb6a1349124560","2780a7f6eed9066af2c9d21346750764","2787358bf9abd7a15ef47d1349033878","2793e41e83c48e69c42ab61347914088","283409d6c5a2b9253b130b1345664810","286774babe0a4da63c01a21330432167","28ff940665c73783d1a5791346723541","29d975c32547c55a8451221344185276","2ab9dc6f81613a972ada331325865595","2b032dafd3ab5169e0bdf61335949829","2b0dd20d26fb6c5e9e29d31349108095","2b507300157ab2195a6ebf1348819447","2c215d412fd9d5a4782ae61327595844","2ce64b9d4a3f20591f41761348425973","2d9d439523439dedc9cf3b1348002924","2df88e59837a89a8c856fb1327362021","2e018ad683d1b2a1f8ca071348936447","2e4d135d0b4ba334c70e121343505895","2e72c632c27b7d87dbe9291324845919","2eeef140a1e256f9c8015f1349045690","2f7a9daa9683420daea2f81348033715"

$found = New-Object -TypeName psobject -Property @{ids=@(); lines=@()}

$found.ids = $ids;

Measure-Command {  gci *.log | %{foreach ($id in $ids){ sls -Path $_.Fullname -Pattern "WT.vtid=$id"}} | %{$found.lines += $_.Line; } }



Measure-Command { gci *.log | %{sls -Path $_.FullName -Pattern "WT.vtid=$patt"} | %{$found.lines += $_.Line; } }

$patt = $found.ids -join "|";

if($target.length -gt 25){
    if($target.Contains("=")){
        $temp=$target.split('=')[0];
    }
}

WT.z_notificationType
$str = "dcsujk3mevz5bd24ybym1q97z_9y6h-dcs-2012-09-17-00-0000-0009-1347841585-pdxsplit04_sp1.log"

$str.Substring(0,$str.Length/4) + "--" + $str.Substring(($str.Length/4)*3)
$str.Substring(0,$str.Length/4) + "--" + $str.Substring(($str.Length-6))
dcsujk3mevz5bd24ybym1q--585-pdxsplit04_sp1.log

function Resize-wtString{
    param(
            [parameter(Mandatory=$true)]
            [string]
            $str        
         )
    begin{
        $truncated = $str;
        $date = Get-Date -UFormat "%H%M%S";
    }

    process{
        if($str.Length -gt 30){
        $truncated = $str.Substring(0,$str.Length/4) + "-$date-" + $str.Substring(($str.Length-6));
        }
    }

    end{
        return $truncated;
    }
}


function Start-wtTimer
<#
.Synopsis
   Set the starting point of a timer.
.DESCRIPTION
   Returns a datetime object intended to be used with the Stop-wtTimer 
   function to time the duration of a command process.  Typically to
   be used inside a function rather than from the commandline.
.EXAMPLE
   $start = Start-wtTimer;
.Outputs
   A DateTime object.
#>

{
    Begin
    {
        [datetime]$stime = Get-Date
    }
    Process
    {
    }
    End
    {
        return $stime;
    }
}

function Stop-wtTimer
<#
.Synopsis
   Set the stopping point of a timer.
.DESCRIPTION
   Returns a TimeSpan object the represents the duration between a starting
   DateTime object and the point at which Stop-wtTimer is called.
.EXAMPLE
   $duration = Stop-wtTimer $start;

   Where $start represents the DateTime object generated by Start-wtTimer;
.Outputs
   A TimeSpan object.
#>
{
    param(
            [parameter(Mandatory=$true)]
            [datetime]$start
         )

    Begin
    {
        [datetime]$end = Get-Date;
        [timespan]$elapsed = 0;
        
    }
    Process
    {
        $elapsed = $end - $start;
    }
    End
    {
        return $elapsed;
    }
}


$stime = Get-Date
$etime = Get-Date;
		$ptime = $etime - $stime;
		Write-Host ("Processing time was {1}:{2}:{3}." -f $ptime.Hours,$ptime.Minutes,$ptime.Seconds);


Get-ChildItem *.log | `
ForEach-Object{ Get-Content $_.FullName | ForEach-Object{$_.TrimEnd(" ")} | `
Set-Content ($_.PSParentPath + "\" + $_.PSChildName + "_fixed.log") } 


Get-ChildItem *.log | `
ForEach-Object{ Get-Content $_.FullName | ForEach-Object{$_.TrimEnd(" ") } | `
  Set-Content ($_.PSParentPath + "\" + $_.PSChildName + "_fixed.log") -Encoding Unicode `
  } 

  
Measure-Command { gci *_padded.log | %{ gc $_.FullName | %{$_.TrimEnd(" ") } | sc ($_.PSParentPath + "\" + ($_.PSChildName -replace "padded","fixed")) -Encoding Unicode } }

gci *.log | %{ gc $_.FullName | %{$_.PadRight($_.length+2) } | sc ($_.PSParentPath + "\" + $_.PSChildName + "_padded.log") -Encoding Unicode } 

gci *_padded.log | %{ gc $_.FullName | %{$_.TrimEnd(" ") } | sc ($_.PSParentPath + "\" + ($_.PSChildName -replace "padded","fixed")) -Encoding Unicode }

Get-ChildItem *_padded.log | `
%{ Get-Content $_.FullName | `
ForEach-Object{$_.TrimEnd(" ") } | `
Set-Content ($_.PSParentPath + "\" + ($_.PSChildName -replace "padded","fixed")) -Encoding Unicode }

# for zinio


Measure-Command {  gci *.log | %{foreach ($id in $ids){ sls -Path $_.Fullname -Pattern "WT.vtid=$id"}} | %{$found.lines += $_.Line; } }

 # create an object to hold the array of id's to search for, the lines found, and the parameter to search for
$found = New-Object -TypeName psobject -Property @{param="";ids=@(); lines=@()}
 # set the param property to the parameter name
$found.param="WT.vtid"
 # set the ids property to the array of values to look for
$found.ids = "2b032dafd3ab5169e0bdf61335949829","2ce64b9d4a3f20591f41761348425973","2d9d439523439dedc9cf3b1348002924","2df88e59837a89a8c856fb1327362021"
 # Measure-Command is just a timer, it can be dispensed with.  Sometimes,
 # it's useful to run the command on a subset to determine how long the whole
 # process will take
 # The command picks up each log file in the directory and passes it to the looping object
 # The looping object passes the file contents to the foreach loop, which then loops through 
 # each item in the array and checks the current line against the array elements
 # each matching line is collected and then added to the $found.lines array.
 # With 30 items in the array, it took 6 hours to run through 25 GB of log files
Measure-Command {  gci *.log | %{foreach ($id in $found.ids){ sls -Path $_.Fullname -Pattern "$found.param=$id"}} | %{$found.lines += $_.Line; } }
 # write out the matching lines to a file
$found.lines | sc C:\users\powem\Desktop\vtid_found_lines.log
 # find the actual array elements that were matched in the log files
 # writes them to the console
$idlist = gc .\vtid_found_lines.log | %{foreach($id in $found.ids){if($_ -match $id) {$id;break }  }  }


$track = ls -Recurse -File | %{sls -Pattern "dcsMultiTrack" -path $_.Fullname}
$track | %{$_.Line} | sc "c:\users\powem\desktop\multi.log"

function Backup-LocalFiles{

    param(
        [parameter(Mandatory=$false)]
        [alias("s")]
        [string]$source="*",
        [parameter(Mandatory=$true)]
        [alias("d")]
        [string]$destination
    )

    begin{
        if(-not(Test-Path $source)){
            throw [System.IO.DirectoryNotFoundException] "Source directory not found.";
        }

        if(-not(Test-Path $destination)){
            throw [System.IO.DirectoryNotFoundException] "Destination directory not found";
        }
    }

    process{
        try{
            Measure-Command { 
                Copy-Item -Recurse -Force $source $destination;
            };
        } catch([System.UnauthorizedAccessException] $e){
            
        }
    }

    end{}

}

function Backup-wtClients{

    param(
        [parameter(Mandatory=$false)]
        [string]$source = ""
    )

    begin{
        $source = "";
        $destination = "";
    
    }

    process{}

    end{}


} # end client backup

$idlist = gc .\vtid_found_lines.log | %{foreach($id in $ids){if($_ -match $id) {$id;break }  }  }


$restConfig = @{user="zinio\wt-mpowe";pass="Pa55w0rd@";version = 'v3';profile = '36519';report = 'WPAHs5Ljtv6';type = 'indv';totals = 'none';format = 'html';measures = '0';}
	
	$restConfig.version = 'v3';
	$restConfig.profile = '36519';
	$restConfig.report = 'WPAHs5Ljtv6';
	$restConfig.type = 'indv';
	$restConfig.totals = 'none';
	$restConfig.format = 'html';
	$restConfig.measures = '0';
	$restConfig.user = $user
	$restConfig.pass = $pass

$query = "WT.dc=unknown&WT.ti=Glamour%20Russia%20October%202012&WT.z_LabelType=2040&WT.vt_sid=2e53be7de07e3d254fb9f91326489713.1348253262628&WT.a_nm=Zinio&WT.vtid=2e53be7de07e3d254fb9f91326489713&WT.co=yes&WT.co_f=2e53be7de07e3d254fb9f91326489713&WT.a_cat=News&WT.rv=1&WT.dl=60&WT.pi=Publication%20View%20Folio%20View&WT.z_OfflineFlag=N&WT.ev=view&WT.mo_or=portrait&WT.pn_sku=416237522&WT.pn_fa=500574457&WT.g_co=unknown&WT.os=6.0&WT.a_pub=Zinio&WT.ct=ReachableViaWiFi&WT.av=2.2.6&WT.z_ActivityDate=09%2F21%2F2012&WT.vtvs=1348253262628&WT.cg_n=Read&WT.dm=iPad3,1&WT.sys=button&WT.z_page=229&WT.uc=Danmark&WT.ets=1348255840449&WT.sr=1536x2048&WT.ul=dansk&WT.z_newss=94070111&WT.tz=2&WT.dcsvid=3581639142";



New-IseSnippet


 
