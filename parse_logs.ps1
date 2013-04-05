# $Id: parse_logs.ps1,v 1.1 2009/10/31 15:19:32 powem Exp $
# parse log files with regular expression
# 23 Sept 2009

$input = "c:\share\logs\horizon_corp\dcsg93sslqmglnyem5cc9vcb5_7u8m-dcs-2009-09-16-12-00001-emsa905z.log";
$output = "c:\share\logs\horizon_corp\output_test.log";
$log = "c:\share\logs\horizon_corp\process_log.log";

$stopWatch = [System.Diagnostics.Stopwatch]::StartNew();
$logPtr = [System.IO.File]::Open($log, [System.IO.FileMode]::Append);


# date time c-ip cs-username cs-host cs-method cs-uri-stem cs-uri-query sc-status sc-bytes cs-version cs(User-Agent) cs(Cookie) cs(Referer) dcs-id

$lrs = 	"(?<date>.*) (?<time>.*) (?<cip>.*) (?<csusername>.*)" + 
		" (?<cshost>.*) (?<csmethod>.*) (?<csuristem>.*) (?<csuriquery>.*)" + 
		" (?<scstatus>.*) (?<scbytes>.*) (?<csversion>.*) (?<csUserAgent>.*)" + 
		" (?<csCookie>.*) (?<csReferer>.*) (?<dcsid>.*)";
$testHost = "testing\.horizon-bcbsnj\.com";
$testHostString = "testing.horizon-bcbsnj.com";
$testCounter = 0;
$lineCounter = 0;

$filePtr = [System.IO.File]::OpenText($input);
$i = 0;
Write-Host "Beginning processing...";
if ($stopWatch.IsRunning -eq $true){
	Write-Host "Clock is ticking.";
} else {
	Write-Host "We're off the clock.";
}

while (! $filePtr.EndOfStream) {
	$line = $filePtr.ReadLine();
	$lineCounter++;
	
	if ($lineCounter % 10 -eq 0){
		Write-Host $lineCounter " lines processed.";
		Write-Host $testCounter " test hits found.";
		Write-Host "Elapsed time: "$stopWatch.Elapsed.Minutes":"$stopWatch.Elapsed.Seconds;
	}
	
	if (! $line -contains $testHostString){
		continue;
	}
	
	# $m = $line -match $lrs;
	
	if (($line -match $lrs) -eq $true){
		if ($matches.cshost -match $testHost){
			$testCounter++;
		}
	}
}

$filePtr.Close();
$stopWatch.Stop();
Write-Host "Testing hits: " $testCounter;
Write-Host "Total lines processed: " $lineCounter;
Write-Host "Elapsed time: " $stopWatch.Elapsed.Minutes ":" $stopWatch.Elapsed.Seconds;
Write-Host "----------";
Write-Host "Finished processing.";