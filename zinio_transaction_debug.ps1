<#

.Synopsis
 Script to retrieve transaction data from ios error logging profile.

.Description
 This script connects to the iOS Error Logging profile and pulls data from
 the original Transaction ID Event Trace report.  The report to pull from can be
 changed on the command line by passing in the report GUID as the third argument to the
 script.  The data extraction filters the data to include only items which have an 
 improper Transaction ID.

.Parameter aStart
 The start date in the standard WebTrends web services format, e.g. "2012m09d01"

.Parameter aEnd
 The end date in the standard Webtrends web services format, e.g. "2012m09d30"

.Parameter aReport
 Optional parameter that takes the report GUID.  Default is to pull from the
 original Transaction ID error report.

.Example
 .\zinio_transaction_debug.ps1 "2012m09d01" "2012m09d30"

 Pull the data from the default report for the date period 1 Sept 2012 to 30 Sept 2012

.Example
 .\zinio_transaction_debug.ps1 "2012m09d01" "2012m09d30" "vqW1RZRkdX6"

 Pull the data from the new report with ETS for the same date period.

.Example
 .\zinio_transaction_debug.ps1 "2012m10d10" "2012m10d10"

 Pull the data for the single day 10 Oct 2012.

.Outputs
 Writes a file to the user desktop with the data.  Uses $env:USERPROFILE environmental 
 variable to find the desktop.  The output file is datestamped, e.g. 
 zinio_transactions_20121010_122802.html. Output is in HTML.

.Notes
 
 Report GUIDS
 WPAHs5Ljtv6 - Transaction ID Event Trace All Events (default)
 vqW1RZRkdX6 - Transaction ID Event Trace All Events with ETS

 $Id: zinio_transaction_debug.ps1,v 1.3 2012/10/10 16:58:04 powem Exp $
 Last revised: $Date: 2012/10/10 16:58:04 $
 Version when it left home: $Revision: 1.3 $
 Author:  Michael Powe, Webtrends Technical Account Manager



#>



param(
        [parameter(Mandatory=$true)]
        [string]$aStart,
        [parameter(Mandatory=$true)]
        [string]$aEnd, 
        [parameter(Mandatory=$false)]
        [string]$aReport);

#region Declarations and Functions


function Set-wtRestConfiguration{

    begin{
        [string]$report = "";
        if(-not($aReport)){
            $report = 'WPAHs5Ljtv6';
        } else {
            $report = $aReport;
        }
    }

    process{
        $restConfig = @{
        user="zinio\wt-mpowe";
        pass="Pa55w0rd@";
        version = 'v3';
        profile = '36519';`
        report = $report;
        type = 'indv';
        totals = 'none';
        format = 'html';
        measures = '0';
        # query = '';
        query = '[Transaction ID] LIKE com.* AND [iOS Transaction ID TimeStamp] NEQ "None"';
        }
    }

    end{return $restConfig;}
    
}


function Get-RestData{

<#
 .Synopsis 
  Retrieve report data from WebTrends via REST API.
 
 .Description
  A simple retrieval mechanism for REST data from WebTrends API.  Pass in 
  the start and end dates in proper format.   Use a hashtable for the other 
  essential values.  This function builds the data request for report data 
  only.
  
  The data is collected in an object, which is returned from the function.
  The object contains a property 'Count', which can be used to see the size
  of the returned data string.  The property 'Data' contains the full string
  returned in response to the request.
  
 .Parameter Start
  The start date in proper format, e.g. 2011m01d01.
  
 .Parameter End
  The end date in proper format.
  
 .Parameter Conf
  A hashtable containing configuration information for the data pull.  The 
  hashtable should contain the following elements:
  version,profile ID, report GUID, type (agg,indv or trend), totals 
  (all, none or only), format (html, json, xml or xml2),  measures 
  (measures=0*1*3 or measures=99 for all measures), username (acct\login), 
  password.
  -----
  
  $restConfig = @{version="v3";
				profile="21897";
				report="hGgJLBjviR6";
				type="indv";
				totals="none";
				format="html";
				measures="measures=0*1*2";
				user="acct\login";
				pass="password"}
  
 .Outputs
  An object that contains the data retrieved and a count indicating the length of the data.
  
 .Notes
  This function uses the StreamReader method ReadToEnd(), so a huge data response may break.
  The usual breakage is that the server closes the stream.  I assume that this happens 
  because the server has a built-in limit to the amount of data it will return in a single
  request. The solution is to chunk up the requests and then reassemble the chunks after
  they've all been retrieved.
  
  Some trivial exception handling is included, which may prevent falling into an infinite
  loop of errors if something goes wrong.
#>


	param (
	[parameter(Mandatory = $true)] [string]$Start,
	[parameter(Mandatory = $true)] [string]$End,
	[parameter(Mandatory = $true)] [hashtable]$Conf)
	
	$version = $Conf.version
	$profile = $Conf.profile
	$report = $Conf.report
	$type = $Conf.type
	$totals = $Conf.totals
	$format = $Conf.format
	# put in a nonsense number to include all measures
	$measures = $Conf.measures
	
	#$URL = "https://ws.webtrends.com/$version/Reporting/profiles/$profile/reports/$report/?totals=$totals&start_period=$start&end_period=$end&period_type=$type&$measures&format=$format&suppress_error_codes=true"
	$URL = "https://ws.webtrends.com/{0}/Reporting/profiles/{1}/reports/{2}/?totals={3}&start_period={4}&end_period={5}&period_type={6}&{7}&format={8}&query={9}&suppress_error_codes=true" -f `
	$Conf.version, `
	$Conf.profile, `
	$Conf.report, `
	$Conf.totals, `
	$Start, $End, `
	$Conf.type, `
	$Conf.measures, `
	$Conf.format, `
    [Web.Httputility]::UrlEncode($Conf.query)
	
	$Username = $Conf.user
	$Password = $Conf.pass
	$UserAgent = $env:USERNAME+":"+$env:COMPUTERNAME

	$restData = New-Object -TypeName psobject -Property @{Length=0; Data=""};

	$URI = New-Object System.Uri($URL,$true)
	$request = [System.Net.HttpWebRequest]::Create($URI)

	$request.UserAgent = $(
	"{0} (PowerShell {1}; .NET CLR {2}; {3})" -f $UserAgent, 
	$(if($Host.Version){$Host.Version}else{"1.0"}),
	[Environment]::Version,
	[Environment]::OSVersion.ToString().Replace("Microsoft Windows ", "Win"))

	#Establish the credentials for the request

	$creds = New-Object System.Net.NetworkCredential($Username,$Password)

	$request.Credentials = $creds
	
	# Thrown if the request times out
	trap [System.Net.WebException] { "A web exception was thrown, possibly caused by a timeout: $_"; break; }

	$response = $request.GetResponse()
	$reader = [IO.StreamReader] $response.GetResponseStream()
	
	# thrown by ReadToEnd()
	trap [System.IO.IOException] { "An IO exception occurred on StreamReader: $_"; break }
	trap [System.OutOfMemoryException] { "An OutOfMemoryException occurred on StreamReader: $_"; break }
	
	$responseHTML = $reader.ReadToEnd()
	
	$restData.Data = $responseHTML
	$restData.Length = ($restData.Data).Length
	
	if ($reader -ne $null){
		$reader.Close()
	}
	if ($response -ne $null){
		$response.Close()
	}
	
	return $restData
} # end get-restdata

function Get-wtiOSTransactions{

    param(
        [parameter(Mandatory=$false)]
        [alias("s")]
        [string]$Start = $aStart,
        [parameter(Mandatory=$false)]
        [alias("e")]
        [string]$End = $aEnd
    )

    begin{

        $Conf = Set-wtRestConfiguration;
        $startdate = $aStart;
        $enddate = $aEnd;
        $data = New-Object -TypeName psobject;
        $datestamp = Get-Date -UFormat "%Y%m%d_%H%M%S";
    }

    process{
    
        $data = Get-RestData -Start $startdate -End $enddate -Conf $Conf;
    
    }

    end{
        Write-Host ("Content length returned is {0} bytes." -f $data.Length);
        $data.Data | sc ("C:\Users\powem\Desktop\zinio_transactions_{0}.html" -f $datestamp)
    }




} # end get-wtiostransactions

#endregion

#region Data Collection

Get-wtiOSTransactions



#endregion