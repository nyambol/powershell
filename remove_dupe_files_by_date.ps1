# 
# Remove Duplicate Files By Date
# This script takes a command line argument of an SDC server and a 
# file date string and removes files in the working directory that 
# match that date and already have a copy of that file in the archive 
# directory.  If the file doesn't already exist in archive, it is moved
# from working to archive.
#
# $Id: remove_dupe_files_by_date.ps1,v 1.6 2008/12/31 13:11:20 powem Exp $
#
# Michael Powe
# Technology Leaders, LLC
# Created: 29 December 2008

# dcspa74f810000spqr4fuho2j_2f8z-dcs-2008-09-01-16-00317-s171i012.log

$global:sdcUser = "adminSDC";
$global:sdcPass = "@dm1nSDC";

# ==================== command line processing ========================
# Generate error message if arguments are not proper.
function usage(){
	Write-Host -ForegroundColor Red "Usage: remove_dupe_files_by_date.ps1 <system number> <date>";
	Write-Host "Where <system number> is 177, 178, or 187 to identify the SDC server";
	Write-Host "And <date> is a date string such as '9/1/08'.  Any numerical date format";
	Write-Host "such as the above will work."
}

if($Args.Length -ne 2){
	Throw New-Object system.ArgumentException;
}

trap [System.ArgumentException]{
	Write-Host -foregroundcolor Red "Exception: $_ ";
	Write-Host;
	usage;
	exit 1;
}

[string]$serverId = $Args[0].toUpper();
[string]$newDate = $Args[1];

[string]$fileDate = Get-Date $newDate -Format "yyyy-MM-dd";

[string]$SdcArchive = "";
[string]$SdcStorage = "";

[int]$global:moveCount = 0;
[int]$global:delCount  = 0;

# This works by connecting to the authenticating share and confirming that the attempt
# completed successfully.  If the connection was not successful, then the script will
# exit immediately with a message. Otherwise, the working and archive directory variables
# are appropriately set.
# The fall-through entry is to local shares on the test system (i.e., will not work 
# anywhere else!)
switch ($serverId){

	"177" {
		$result = (net use \\53.67.15.177\weblog /user:$global:sdcUser $global:sdcPass | Select-String "successfully");
		if ($result -eq $null){
			Write-Host "Share access failed for 177.  Exiting.";
			exit 1;
		} else {
			$SdcArchive = "\\53.67.15.177\weblog\archive";
			$SdcStorage = "\\53.67.15.177\weblog";
		}
		break;
	}
	"178" {
		$result = (net use \\53.67.15.178\weblog /user:$global:sdcUser $global:sdcPass | Select-String "successfully");
		if ($result -eq $null){
			Write-Host "Share access failed for 178.  Exiting.";
			exit 1;
		} else {
			$SdcArchive = "\\53.67.15.178\weblog\archive";
			$SdcStorage = "\\53.67.15.178\weblog";
		}
		break;
	}
	"187" {
		$result = (net use \\53.67.15.187\weblog /user:$global:sdcUser $global:sdcPass | Select-String "successfully");
		if ($result -eq $null){
			Write-Host "Share access failed for 187.  Exiting.";
			exit 1;
		} else {
			$SdcArchive = "\\53.67.15.187\weblog\archive";
			$SdcStorage = "\\53.67.15.187\weblog";
		}
		break;
	}
	"L177"{
		$SdcArchive = "D:\WTlogs\177\archive";
		$SdcStorage = "D:\WTlogs\177";
		break;
	}
	"L178"{
		$SdcArchive = "D:\WTlogs\178\archive";
		$SdcStorage = "D:\WTlogs\178";
		break;
	}
	"L187"{
		$SdcArchive = "D:\WTlogs\187\archive";
		$SdcStorage = "D:\WTlogs\187";
		break;
	}
	default{
		$SdcArchive = "\\ctpowem01\share\logs\test1";
		$SdcStorage = "\\ctpowem01\share\logs\test2";
	}
}
# ===================== end commandline processing =======================

# This function creates a hashtable of files using the date string passed in 
# on the command line.  The file name is the key and the location of the file
# is the value.  Only files which have the date string in the name are captured.
function getFiles([string]$filePath){

	$filesList = New-Object system.Collections.Hashtable;
	gci $filePath -Filter "*$fileDate*" | foreach {$filesList.($_.Name)=$_.FullName};
	Write-Host $filesList.Count " files found in " $filePath;
	return $filesList;
}

# Processing is done by comparing the file names in the keys of hashtables created
# for the working directory and the archive directory.  If a file exists in the archive
# and in the working, then it is removed (deleted) from the working.  If a file does not
# exist in the archive, then it is moved there.
function processFiles(){

	$archiveFiles = New-Object system.Collections.Hashtable;
	$workingFiles = New-Object System.Collections.Hashtable;
	
	$archiveFiles = getFiles($SdcArchive);

	$workingFiles = getFiles($SdcStorage);
	
	$archiveKeys = $archiveFiles.keys;
	$workingKeys = $workingFiles.keys;
	
	foreach ($key in $workingKeys){
	
		if ($archiveKeys -contains $key){
			Remove-Item $workingFiles[$key];
			$global:delCount++;
		} else {
			Move-Item $workingFiles[$key] $SdcArchive;
			$global:moveCount++;
		}
	} # end foreach loop
} # end function processFiles

# script block to do the processing.
&{
	processFiles;
	Write-Host;
	Write-Host "Processing completed.";
	Write-Host $global:delCount " files deleted.";
	Write-Host $global:moveCount " files moved.";
}


