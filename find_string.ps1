function Find-WtString{
<# 
 .Synopsis
  Find a given string or substring value in a set of log files.

 .Description
  Captures strings or substrings based on a given regular expression and writes
  the resulting captures to a file.  Designed specifically to work on web log files,
  either SDC or web server logs.

 .Parameter Query
  Switch to identify the search as taking place in the query string field.

 .Parameter Help
  Prints a help message.

 .Parameter SearchTerm
  The regular expression or string to be searched. The search is a regular expression
  search, so if the string passed in is not in regular expression format with a capture
  group, a capture group will be added to it.

 .Example
  # Capture all the URLs in the cs-uri-stem field.
   
  WT-Find-String "[ ]+GET[ ]+([^ ]+).*"
   
  Description
  -----------
  This regular expression looks for the text field immediately following the 
  cs-method field containing the GET method.  It then captures everything up 
  to the next space character.

 .Example
  # Capture all the values of the query parameter WT.mc_id that consist of exactly the string PUB_WWW_F.
   
  WT-Find-String "WT\.mc_id=(PUB_WWW_F)&"
   
  Description
  -----------
  Without the -query switch, the search string must specify exactly how to 
  capture a value within the query string.  This means specifying either a 
  terminating ampersand or end-of-string (probably a space).

 .Example
  # Capture all values of the query parameter WT.mc_id.  
	 
  WT-Find-String -query WT.mc_id
   
  Description
  -----------
  Using the -query switch causes the function to treat the given string as a
  parameter name and look for the _values_ within the query string, rather than
  looking for the string itself.
#>
	param([switch] $query, 
		  [parameter(Mandatory=$true)] [string]$searcher,
		  [parameter(Mandatory=$false)] [string]$file
		 )
	
	begin {
		$wt = "" | select File,Lines,Count
		$items = 0
		$wtmatches = @{}
		$original = ($searcher -replace "[*.\\?]",'_')
		$datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"
		[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
		$path = (Get-Location).Path
		
	 	if ( -not((ls *.log).length -gt 0) -and -not($file)){ 
	 		Write-Host "No log files found in current directory, $path"
			Write-Host "You must be in the log directory to run this function."
			Write-Host "Exiting now."
			return 1
		}
	}
	
	process{
		if ($query){
		    if (-not($searcher.Contains("(")) -and -not($searcher.Contains("=")) ){
		         $searcher += "=([^& ]+)"
		    } elseif ($searcher.Contains("=") -and -not($searcher.Contains("("))){
		         $stemp = $searcher.split("=")
		         $stemp[1] = "({0}[^& ]+)" -f $stemp[1]
				 $searcher = ("{0}={1}" -f $stemp[0], $stemp[1])
		    }
		    Write-Host ("Searching files on {0} for {1}" -f $path, $searcher)
			
			if ($file){
				$m = (select-string -path $file -pattern $searcher) 
				$m | Foreach-Object{
					$wtmatches[$_.Matches[0].Groups[1].Value]++; 
					$items++;
					
				}
			} else {
			    $m = (select-string -path "*.log" -pattern $searcher) 
				$m | Foreach-Object{
					$wtmatches[$_.Matches[0].Groups[1].Value]++; 
					$items++;
					
				}
			}
			
			$m = $null
		    if ($wtmatches.Count -gt 0){
				$wt.Lines = $items
				$strmatch = @();
				$strmatch += ("Total line count of matching items was {0}" -f $items)
				$strmatch += ("Total unique items is {0} " -f $wtmatches.Count)
				$strmatch += "----"
				$wtmatches.GetEnumerator() | Sort-Object -Property Value -Descending |
				Foreach-Object{$strmatch += $_.key}
		         Set-Content -Path ("{0}\Desktop\{1}_found_{2}.log" -f $env:USERPROFILE, $original, $datestamp ) $strmatch
				 Write-Host ("`nFound {0} matching lines." -f $items)
		         Write-Host ("Wrote {0} unique items to file." -f $wtmatches.Count)
		    } else {
		         Write-Host ("No matches found for {0}." -f $searcher)
		    }
		} else {
			if (-not($searcher.Contains("("))){
				$searcher = ("({0})" -f $searcher)
			}
			Write-Host ("Searching files on {0} for {1}" -f $path, $searcher)
			(select-string -path "*.log" -pattern $searcher) | 
			Foreach-Object{$wtmatches[$_.Matches[0].Groups[1].Value]++; $items++}
		     if ($wtmatches.Count -gt 0){
		        $strmatch = @();
				$strmatch += ("Total line count of matching items was {0}" -f $items)
				$strmatch += ("Total unique items is {0} " -f $wtmatches.Count)
				$strmatch += "----"
				$wtmatches.GetEnumerator() | Sort-Object -Property Value -Descending |
				Foreach-Object{$strmatch += $_.key}
		         Set-Content -Path ("{0}\Desktop\{1}_found_{2}.log" -f $env:USERPROFILE, $original, $datestamp ) $strmatch
				 Write-Host ("`nFound {0} matching lines." -f $items)
		         Write-Host ("Wrote {0} unique items to file." -f $wtmatches.Count)
		     } else {
		         Write-Host ("No matches found for {0}." -f $searcher)
		     }
		}
	}
	end {
     	Write-Host "`nFinished."
	}
}