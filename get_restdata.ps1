# $Id: get_restdata.ps1,v 1.1 2012/03/09 16:06:26 powem Exp $
# Last Modified: $Date: 2012/03/09 16:06:26 $
# $Revision: 1.1 $
# Michael Powe
# WebTrends Technical Account Manager
# 3 March 2012


function Set-RestHash{
	param([parameter(Mandatory=$true,
					 HelpMessage="API version, e.g. v3.")] $version,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Profile number, e.g. 27211.")] $profile,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Report number, e.g. 18d039ae036.")] $report,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Data type: 'agg', 'trend', 'indv'.")] $type,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="totals: 'all', 'none', 'only'.")] $totals,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="format: 'html', 'xml', 'xml2', 'json'.")] $format,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="Measures, e.g. '99' for all measures or '0,1,2' for 1st 3.")] $measures,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="user login in the format domain\login-name")] $user,
		  [parameter(Mandatory=$true,
		  			 HelpMessage="user's login password.")] $pass
		 )
	
	$restConfig = @{}
	
	$restConfig.version = $version
	$restConfig.profile = $profile
	$restConfig.report = $report
	$restConfig.type = $type
	$restConfig.totals = $totals
	$restConfig.format = $format
	$restConfig.measures = "measures={0}" -f $measures
	$restConfig.user = $user
	$restConfig.pass = $pass
	
	return $restConfig

}

function Split-RestUrl {

	param([parameter(Mandatory = $true)] [string] $restUrl)
	
	$restConfig = @{}
	
	#$URL = "https://ws.webtrends.com/v3/Reporting/profiles/21897/reports/hGgJLBjviR6/?totals=none&start_period=2011m01d01&end_period=2011m01d31&period_type=indv&measures=0*1*2&format=html&suppress_error_codes=true"
	$ws_uri_regex = "https?://(?<domain>[a-z]+\.[a-z]+\.com)/(?<version>[a-z0-9]+)/[^/]+/[^/]+/(?<profile>[0-9]+)/reports/[^/]+/\?.*"
	$ws_qry_regex = ""
	$query = $restUrl.split('?')[1]
	
	
	
	$fields = $query.split('&')
	
	
	
	return $restConfig
}

function Get-RestData{

<#
 .Synopsis 
  Retrieve report data from WebTrends via REST.
 
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
	$URL = "https://ws.webtrends.com/{0}/Reporting/profiles/{1}/reports/{2}/?totals={3}&start_period={4}&end_period={5}&period_type={6}&{7}&format={8}&suppress_error_codes=true" -f `
	$Conf.version, `
	$Conf.profile, `
	$Conf.report, `
	$Conf.totals, `
	$Start, $End, `
	$Conf.type, `
	$Conf.measures, `
	$Conf.format
	
	$Username = $Conf.user
	$Password = $Conf.pass
	$UserAgent = $env:USERNAME+":"+$env:COMPUTERNAME

	$restData = "" | Select-Object Count,Data

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
	$restData.Count = ($restData.Data).Length
	
	if ($reader -ne $null){
		$reader.Close()
	}
	if ($response -ne $null){
		$response.Close()
	}
	
	return $restData
}
