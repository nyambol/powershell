# $Id: remove_dupe_files.ps1,v 1.4 2009/10/31 15:17:34 powem Exp $
# 
# Remove duplicate SDC log files from the original
# directory

# location of the SDC share.
[string]$SdcStorage = "\\ctpowem01\share\logs\test1";
# location of the WebTrends log archive share.
[string]$WtStorage = "\\ctpowem01\share\logs\test2";
# Can't set a String in PS to $null, it will be coerced to "".
[string]$errPath="";

$global:dupeTotal = 0;

function removeDuplicateFiles(){
	Write-Host "Gathering source files ... ";
	$srcList = @(Get-ChildItem -Name $SdcStorage -Include "*.log");
	Write-Host $srcList.length " source files.";
	Write-Host "Gathering destination files ... ";
	$destListNames = @(Get-ChildItem -Name $WtStorage -Include "*.log");
	Write-Host $destListNames.length " destination files.";
	
	$dupeCount = 0;
	
	if ($srcList -eq $null){
		$errPath = "(Origin) " + $SdcStorage;
		Throw New-Object System.IO.FileNotFoundException;
	}
	if ($destListNames -eq $null){
		$errPath = "(Dest) " + $WtStorage;
		Throw New-Object System.IO.FileNotFoundException;
	}
	
	foreach ($file in $srcList){
		for($i=0; $i -lt $destListNames.length; $i++){
			if ($file.Equals($destListNames[$i])){
				Remove-Item "$SdcStorage\$file";	
				$dupeCount++;
				$global:dupeTotal = $dupeCount;
				break;
			}
			if ($dupeCount % 100 -eq 0){
				Write-Host $dupeCount " files deleted.";
			}
		}
		# Write-Host $file.Name;
	}
	
	
	trap [System.IO.FileNotFoundException] {
		Write-Host $_.Exception.Message;
		Write-Host "Path: $errPath";
		exit 1;
	}
} # end function

& {
	removeDuplicateFiles;
	Write-Host "End duplicate file removal process.";
	Write-Host "$global:dupeTotal duplicate files removed.";
}