# $Id: propercase_strings.PS1,v 1.1.1.1 2008/08/28 00:58:34 powem Exp $
# Purpose:
# $Date: 2008/08/28 00:58:34 $

# convert a string into proper case (e.g., from THIS to This)

#String.prototype.toProperCase = function()
#{
#  return this.toLowerCase().replace(/^(.)|\s(.)/g, 
#      function($1) { return $1.toUpperCase(); });
#}

$strTest = "12345, `"this one, too`", `"that one, also`""

function getStream([string]$filePath){
	$sr = New-Object system.IO.StreamReader($filePath);
	return $sr;
}

function getSentence([string]$entry){
	$re = New-Object system.Text.RegularExpressions.Regex('([0-9]+),\s?"(.*)",\s?"(.*)"');
	$temp = [regex]::Match($entry,$re);
	$c = 0;
	$itemsHash = @{};
	foreach ($item in $temp.Groups){
		$itemsHash[$c++] = ($item.Value).TrimStart();
	}
	
	return $itemsHash;
}

function toProperCase([string]$newString){

#  return this.toLowerCase().replace(/^(.)|\s(.)/g, 
#  function($1) { return $1.toUpperCase(); });
	$temp = ($newString.toLower()).Replace('^(.)|\s(.)', {return $1.toUpper();});
	
	$letter = ($newString.toCharArray())[0];
	$letter = ($letter.toString()).ToUpper();
	$newString = $newString.toLower();
	return $temp;
	
	#return $newString -replace '^.',$letter;
}

function properCaseString([string]$sentence){
	
	$tempre = New-Object system.Text.RegularExpressions.Regex('\sin\s|\sa\s|\sthe\s');
	$tempSentenceHash = getSentence($sentence);
	$tempString = [regex]::Split($tempSentenceHash[2],",");
	
	for ($i=0; $i -lt $tempString.Length; $i++){
		if ($i -gt 0 -and $tempString[$i] -notmatch $tempre){
			$tempString[$i] = ($tempString[$i]).TrimStart();
			$tempString[$i] = toProperCase($tempString[$i]);
		} else {
			$tempString[$i] = toProperCase($tempString[$i]);
		}
	}
	return $tempString;	
}

toProperCase("This is the one");



