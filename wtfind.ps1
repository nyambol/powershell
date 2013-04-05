# $Id: wtfind.ps1,v 1.1 2011/12/28 16:28:44 powem Exp $
# 
# get a value from a webtrends param and write it to a file
# $srch="WT\.mc_id=(PUB_WWW_F)&";
#function wtfind([string]$searcher){
#	 $t=@(); 
#	 (select-string -path ".\*.log" -pattern $searcher) | %{$t+=$_.Matches[0].Groups[1].Value}; 
#	 Set-Content -Path $env:USERPROFILE\Desktop\found.log $t
#}
$wtfphelp = @"
---
Get the values of a query string parameter from a log or set of logs
and write them to an output file on the user's desktop.
This function assumes that the value to be captured is from a query 
parameter.
* Usage:  wt-find-param "WT\.mc_id=(PUB_WWW_F)&"
In this example, the output file will contain all the instances in 
which the WT.mc_id parameter contained the string 'PUB_WWW_F' only.
* Usage:  wt-find-param WT.mc_id
In this example, the output file will contain all the instances in 
which the WT.mc_id appears with a non-nil value.
* Usage:  wt-find-param WT.mc_id=PUB_WWW_F
In this example, the output file will contain all the instances in
which the WT.mc_id parameter contains the string PUB_WWW_F.  The difference
between this and the first example is that the output will contain all
strings that contain this substring, and not just the ones that end at
the 'F'.
---
"@

function wt-find-param([string]$searcher){
     $t=@()
	 if ($args.length -eq 0){ $wtfphelp; return 1 }
     if (-not($searcher.Contains("(")) -and -not($searcher.Contains("=")) ){
          $searcher += "=([^&]+)"
     } elseif ($searcher.Contains("=") -and -not($searcher.Contains("("))){
          $stemp = $searcher.split("=")
          $stemp[1] = "("+$stemp[1]+"[^&]+)"
          $searcher = $stemp[0]+"="+$stemp[1]
     }
     [Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
     $path = (Get-Location).Path
     Write-Host "Searching files on $path for $searcher"
     (select-string -path "*.log" -pattern $searcher) | %{$t+=$_.Matches[0].Groups[1].Value}
     if ($t.length -gt 0){
          Set-Content -Path "$env:USERPROFILE\Desktop\found.log" $t
          Write-Host ("Wrote",$t.length, "items to file.")
     } else {
          Write-Host "No matches found."
     }
     Write-Host "`nFinished."
}

function wt-find-string([switch] $help, [switch] $query, [string]$searcher){

$wtfphelp = @"
---
Find the matches for a given substring from a log or set of logs
and write them to an output file on the user's desktop.  The output
is the unique values; duplicates are rolled up.
* Optional switch:  -help
  	Prints this message.
* Optional switch:  -query
	If the optional switch -query is used, the search is assumed to be
	in the query string only.  This is useful for a shorthand way of 
	collecting all the values or a subset of values of a particular 
	query string parameter.
	It is important to note that not using the switch can have unexpected
	results.  e.g., wt-find-string WT.mc_id is just going to return 
	'WT.mc_id' for each line in which it is found, while 
	wt-find-string -query WT.mc_id will return the _values_ of the 
	parameter for each line in which it was found.

Examples: 
* Usage w/o switch:  wt-find-string "[ ]+GET[ ]+([^ ]+).*"
	In this example, the output file will contain all the URLs in the
	cs-uri-stem field by capturing everything up to the next space
	(everything which is not a whitespace character).
* Usage w/o switch:  wt-find-string "WT\.mc_id=(PUB_WWW_F)&"
	In this example, the output file will contain all the instances in 
	which the WT.mc_id parameter contained the string 'PUB_WWW_F' only.
* Usage with switch:  wt-find-string -query WT.mc_id
	In this example, the output file will contain all the values for the parameter 
	WT.mc_id when it appears with a non-nil value.  The function will assume
	that the search is taking place only in the cs-uri-query field.
* Usage with switch:  wt-find-string -query WT.mc_id=PUB_WWW_F
	In this example, the output file will contain all the instances in
	which the WT.mc_id parameter contains the string PUB_WWW_F.  The difference
	between this and the first example is that the output will contain all
	strings that contain this substring, and not just the ones that end at
	the 'F'.
---
"@
	if($help){ $wtfphelp; return 1 }
	if (-not($searcher)){ $wtfphelp; return 1 }
	$t=@()
	$wtmatches = @{}
	[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
	$path = (Get-Location).Path
 	if ( -not((ls *.log).length -gt 0)){ 
 		Write-Host "No log files found in current directory, $path"
		Write-Host "You must be in the log directory to run this function."
		Write-Host "Exiting now."
		return 1
	}
	if ($query){
	    if (-not($searcher.Contains("(")) -and -not($searcher.Contains("=")) ){
	         $searcher += "=([^&]+)"
	    } elseif ($searcher.Contains("=") -and -not($searcher.Contains("("))){
	         $stemp = $searcher.split("=")
	         $stemp[1] = "("+$stemp[1]+"[^&]+)"
	         $searcher = $stemp[0]+"="+$stemp[1]
	    }
	    Write-Host "Searching files on $path for $searcher"
	    (select-string -path "*.log" -pattern $searcher) | 
		%{$wtmatches[$_.Matches[0].Groups[1].Value]++}
	    if ($wtmatches.Count -gt 0){
			$strmatch = @();
			$wtmatches.GetEnumerator() | Sort-Object -Property Value -Descending |
			%{$strmatch += $_.key}
	         Set-Content -Path "$env:USERPROFILE\Desktop\found.log" $strmatch
	         Write-Host ("Wrote",$wtmatches.Count, "items to file.")
	    } else {
	         Write-Host "No matches found."
	    }
	} else {
		if (-not($searcher.Contains("("))){
			$searcher = "("+$searcher+")"
		}
		Write-Host "Searching files on $path for $searcher"
		(select-string -path "*.log" -pattern $searcher) | 
		%{$wtmatches[$_.Matches[0].Groups[1].Value]++}
	     if ($wtmatches.Count -gt 0){
	        $strmatch = @();
			$wtmatches.GetEnumerator() | Sort-Object -Property Value -Descending |
			%{$strmatch += $_.key}
	         Set-Content -Path "$env:USERPROFILE\Desktop\found.log" $strmatch
	          Write-Host ("Wrote",$strmatch.length, "items to file.")
	     } else {
	          Write-Host "No matches found."
	     }
	}
     Write-Host "`nFinished."
}