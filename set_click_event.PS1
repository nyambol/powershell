
# $Id: set_click_event.PS1,v 1.5 2008/10/06 11:13:47 powem Exp $
#
# Michael Powe, Technology Leaders, LLC
# 4 Oct 2008
#
# Fix log lines with WT.mc_id but not WT.mc_ev=click,
# which is necessary for Warehouse to work.
# Note:  this script reads the entire file contents into a single string
# in memory.  This is done because we know that the files are relatively 
# small.  Not a good method for large or very large log files.
#
# Requires the Powershell Community Extensions, for the Basename property that gets
# the basename of the files.

# set globally so they're easy to get at
# [string]$logStorage = "C:\share\logs\mercedes\177";
[string]$logStorage = $Args[0];
# logs into the script directory
[string]$loggingFile = ".\set_event.log"; 

# globals to count number of files with matches/no matches.
[double]$matchCount = 0;
[double]$noMatchCount = 0;

# Creates a list of log files and checks for the existence of the campaign event.
# If the event does not exist, skip the file.  Otherwise, open the file and add the
# WT.mc_ev=click identifier.
# Note that this function does not parse the log to determine if the campaign ID is in
# the query string -- it just matches and updates all occurrences, including those in the
# referrer.
function setEvent(){

	$target = "WT.mc_id=";
	$replacement = "WT.mc_ev=click&WT.mc_id=";

	$flag = "_fixed";
	$ext = ".log";

	$srcList = Get-ChildItem -Recurse $logStorage -Include "*.log";

	foreach ($file in $srcList){
		$fileContents = Get-Content $file;
		if (hasEvents($fileContents)){
			$fixedContents = $fileContents -replace $target, $replacement;
			$newFilename = $logStorage + "\" + $file.Basename + $flag + $ext;
			Out-File $newFilename -InputObject $fixedContents -Encoding ASCII;
			$global:matchCount ++ ;
			writeLogEntry("File $newFilename written");
		} else {
			$name = $file.Name;
			$global:noMatchCount ++ ;
			writeLogEntry("No events found in $name.");
		}
	}
} # end setEvent

# regex is created in outer scope so it need only be created once, then called
# repeatedly.
function hasEvents([string]$contents){
	$eventMatch = [regex]::Match($contents,$eventRE);
	return $eventMatch.Success;
}

function writeLogEntry([string]$entry){
	$timeStamp = [datetime]::Now.ToString("MM-dd-yyyy hh:mm:ss");
	$log = $timeStamp + " " + $entry;
	Out-File $loggingFile -InputObject $log -Append -Encoding ASCII;
}

function usage(){
	[string]$script = $MyInvocation.ScriptName;
	Write-Host "Usage:  $script <log file path>";
	Write-Host "Pass in the path to the log files, e.g. $script c:\logs\177";
	exit 1;
}

# script block to do the work
&{

	if($logStorage -eq $null){
		usage;
	}
	
	[string]$begin = "Begin processing...";
	[string]$end = "End processing...";

	# create this once because it's used in every pass of hasEvents.
	[string]$re = "WT\.mc_id";
	$eventRE = New-Object system.Text.RegularExpressions.Regex($re);

	writeLogEntry($begin);

	setEvent;

	# have to set these after setEvent completes in order to get the interpolated variable count.
	[string]$skipped = $noMatchCount.ToString() + " files processed with no events to update.";
	[string]$written = $matchCount.ToString() + " files processed with events updated.";

	writeLogEntry($end);
	writeLogEntry($written);
	writeLogEntry($skipped);
}