# $Id: search_wlp_files.ps1,v 1.2 2012/03/10 17:43:09 powem Exp $
# Last Modified: $Date: 2012/03/10 17:43:09 $
# $Revision: 1.2 $
# Author:  Michael Powe
# Technical Account Manager, WebTrends

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
	Select-String -Path "*.wlp" -Pattern $pattern |
	%{
		$ele = @{}
		$current = $_.Filename
		$ele["Definitions"] = $_.Matches[0].Groups[1].Value
		$name = (Select-String -Path $_.Filename -Pattern "description ?= ?(.+)").Matches[0].Groups[1].Value
		$ele["wlp"] = $current
		$ele["Name"] = $name
		$wlp.Extracts += $ele
		$wlp.Matches++
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
		Set-Content -Path $outpath -Value ("Account: {0},Date: {1},{2} Files Processed" -f $wlp.Account,(Get-Date -Format g), $wlp.Matches)
		Add-Content -Path $outpath -Value ("wlp Filename,Profile Name,{0} Definition" -f $wlp.Element)
		
		$wlp.Extracts | %{
		Add-Content -Path $outpath -Value ("{0},{1},{2}" -f $_.wlp,$_.Name,$_.Definitions)
		}
		
	}
		return $wlp
}
