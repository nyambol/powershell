# $Id: calcDateDiffInDays.ps1,v 1.1 2009/10/31 15:17:34 powem Exp $

# Do simple date math -- determine days between two dates

param([string]$firstDay = $args[0], [string]$secondDay = $args[1]);

function calcElapsedDays([string]$first,[string]$second){

	if ($firstDay -eq "" -or $secondDay -eq ""){
		Write-Host "Missing date parameter.  Need two dates."
		exit;
	}

	[System.Globalization.CultureInfo]$us = New-Object System.Globalization.CultureInfo("en-US");
	
	[DateTime]$firstDate = [DateTime]::Parse($first,$us);
	[DateTime]$secondDate = [DateTime]::Parse($second,$us);
	[DateTime]$diffDate = New-Object DateTime;
	[String]$diffDays = "";
	$msg = "";
	$dayDiffString = "day";
	
	if ($firstDate -gt $secondDate){
			
		[DateTime]$temp = $firstDate;
		$firstDate = $secondDate;
		$secondDate = $temp;
	}
	
	$diffDays = ($secondDate-$firstDate).Days;
	
	if ($diffDays -gt 1){
		$dayDiffString = "days";
	}
	
	Write-Host $diffDays " " $dayDiffString " between " $firstDate.ToShortDateString() " and " $secondDate.ToShortDateString();
}

calcElapsedDays $firstDay $secondDay;