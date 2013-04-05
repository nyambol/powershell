# $Id: webtrends.PS1,v 1.7 2009/10/31 15:17:34 powem Exp $
# Michael Powe
# 2008 Sep 2
# Last modified:  $Date: 2009/10/31 15:17:34 $
# cmdlet functions to start and stop WebTrends services:
# UI, GeoTrends and Scheduler
# usage:  Source this script.  Then:
#         Start-WebTrends geo	-- start the GeoTrends server.
#		  Get-WebTrends         -- get the status of the services.


function Start-WebTrends {

	param([string]$svc=$(Throw "Specify 'ui', 'geo' or 'scheduler'"))
	
	begin {
		$wtsvc = Get-Service -DisplayName "*WebTrends*";
		$wtui  =  $wtsvc | ?{$_.DisplayName -eq "WebTrends - User Interface"};
		$wtgeo =  $wtsvc | ?{$_.DisplayName -eq "WebTrends - GeoTrends Server"};
		$wtsched = $wtsvc | ?{$_.DisplayName -eq "WebTrends - Scheduler Agent"};
	}
	
	process {
		switch (($svc).toLower()){
			"ui"
			{
				if ($wtui.Status -eq "Running"){
					Write-Host "The UI service already is running.";
				} else {
					Write-Host "Starting the WebTrends UI server ...";
					Start-Service wtui;
				}
			}
			"geo"
			{
				if ($wtgeo.Status -eq "Running"){
					Write-Host "The GeoTrends Server already is running.";
				} else {
					Write-Host "Starting GeoTrends Service...";
					Start-Service $wtgeo.Name;
				}
			}

			"scheduler"
			{
				if ($wtsched.Status -eq "Running"){
					Write-Host "The scheduler already is running.";
				} else {
					Write-Host "Starting the scheduler ... ";
					Start-Service $wtsched.Name;
				}
			}	
		} # end switch
	}
	end {
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
} # end Start-WebTrends

function Stop-WebTrends {

	param([string]$svc=$(Throw "specify 'ui', 'geo' or 'scheduler'"));
	
	begin {
		$wtsvc = Get-Service -DisplayName "*WebTrends*";
		$wtui  = $wtsvc | ?{$_.DisplayName -eq "WebTrends - User Interface"};
		$wtgeo = $wtsvc | ?{$_.DisplayName -eq "WebTrends - GeoTrends Server"};
		$wtsched = $wtsvc | ?{$_.DisplayName -eq "WebTrends - Scheduler Agent"};
	}
	
	process {
		switch (($svc).toLower()){
			"ui"
			{
				if ($wtui.Status -eq "Stopped"){
					return "The UI service already is stopped.";
				} else {
					Write-Host "Stopping the UI services ...";
					Stop-Service $wtui.Name;
				}
			}
			"geo"
			{
				if ($wtgeo.Status -eq "Stopped"){
					Write-Host "The GeoTrends Server already is stopped.";
				} else {
					Write-Host "Stopping GeoTrends Service...";
					Stop-Service $wtgeo.Name;
				}
			}
			"scheduler"
			{
				if ($wtsched.Status -eq "Stopped"){
					Write-Host "The scheduler already is stopped.";
				} else {
					Write-Host "Stopping the scheduler ...";
					Stop-Service $wtsched.Name;
				}
			}
		} # end switch
	}
	
	end {
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
} # end function Stop-WebTrends

function Restart-WebTrends {

	param([string] $svc=$(Throw "specify 'ui', 'geo', or 'scheduler'"));
	
	begin {	
		$wtsvc = Get-Service -DisplayName "*WebTrends*";
		$wtui  = $wtsvc | ?{$_.DisplayName -eq "WebTrends - User Interface"};
		$wtgeo = $wtsvc | ?{$_.DisplayName -eq "WebTrends - GeoTrends Server"};
		$wtsched = $wtsvc | ?{$_.DisplayName -eq "WebTrends - Scheduler Agent"};
		[string]$wtSvcName = "";
		Write-Host "Restarting ... ";
	}
	
	process {
		switch (($svc).toLower()){
			"ui"
			{
				$wtSvcName=$wtui.DisplayName;
				if ($wtui.Status -eq "Stopped"){
					Start-Service $wtui.Name;
					Write-Host "Done.";
				} else {
					Stop-Service $wtui.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtui.Name;
				}
			}
			"geo"
			{
				$wtSvcName=$wtgeo.DisplayName;
				if ($wtgeo.Status -eq "Stopped"){
					Start-Service $wtgeo.Name;
					Write-Host "Done.";
				} else {
					Stop-Service $wtgeo.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtgeo.Name;
					
				}
			}
			"scheduler"
			{
				$wtSvcName=$wtsched.DisplayName;
				if ($wtsched.Status -eq "Stopped"){
					Start-Service $wtsched.Name;
					Write-Host "Done.";
				} else {
					Stop-Service $wtsched.Name;
					Start-Sleep -Seconds 5;
					Start-Service $wtsched.Name;
					Write-Host "Done.";
				}
			}
		} # end switch
	
		
	}
	
	end {
		Write-Host "Service status is " (Get-Service -DisplayName $wtSvcName).Status;
		$wtui=$null;
		$wtgeo=$null;
		$wtsched=$null;
		$wtsvc=$null;
	}
} # end function Restart-WebTrends

function Get-WebTrends {

	begin {
		$wtsvc = Get-Service -DisplayName "*WebTrends*" | Sort-Object -Property Status;
	}

	process {
		$svcHeader = [string]::Format("{0,-40}", "Service");
		$svcHeader += [string]::Format("{0,10}", "Status");
		$l = '-' * 50;
		Write-Host $svcHeader;
		Write-Host $l;
		foreach ($svc in $wtsvc){
			$svcStr = [string]::Format("{0,-40}", $svc.DisplayName);
			$svcStr += [string]::Format("{0,10}", $svc.Status);
			Write-Host $svcStr;
		}
	}
	
	end {
		$wtsvc = $null;
	}

} # end function Get-WebTrends
