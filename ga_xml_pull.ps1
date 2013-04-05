# 
# $Id: ga_xml_pull.ps1,v 1.9 2009/10/31 15:17:34 powem Exp $
# script to pull XML from Google Analytics API
# designed after bash scripts from API team
# 24 January 2009

[string]$username = "mpowe@technologyleaders.com";
[string]$password = "Pa55w0rd";

# Set to $true to generate a data feed and XML output.
# Set to $false otherwise.
[Boolean]$accounts = $true;
[Boolean]$report = $true;

# Set to $true to print the token to the console.
[Boolean]$print_token = $false;

# Gets an authorization token string.
# These actually are good for as long as you want to reuse them, so you don't need
# to re-request one for each data connection.
function getAuthToken(){

	[string]$url = "https://www.google.com/accounts/ClientLogin";
	[string]$query = "?Email=$username&service=analytics&Passwd=$password&accountType=GOOGLE";

	trap [Exception] { Write-Host "An error occurred in: " $MyInvocation.InvocationName 
					   Write-Host $_; break; };
	
	$auth_req = [System.Net.WebRequest]::Create($url+$query);
	
	$auth_resp = $auth_req.GetResponse();	
	$auth_resp_stream = new-object System.IO.StreamReader($auth_resp.GetResponseStream());

	while ($auth_resp_stream.EndOfStream -ne $true){
		$line=$auth_resp_stream.readLine();
		if (($line.StartsWith('Auth=') -eq $true)){
			$token = ($line.split("="))[1];
			break;
		}
	} # end while
	return $token;
}

# Gets an XML feed of the account data.  
# Takes the authorization token created above.
function getAccountData([string]$auth_token){

	[string]$acct_data = "";
	[string]$account_url = "https://www.google.com/analytics/feeds/accounts/";
	[string]$account_header = "Authorization: GoogleLogin Auth="+$auth_token;
	
	trap [Exception] { Write-Host "An error occurred in: " $MyInvocation.InvocationName 
					   Write-Host $_; break;  };
	
	$acct_req = [System.Net.WebRequest]::Create($account_url+"mpowe@technologyleaders.com");
	$acct_req.Headers.Add($account_header);
	
	$acct_resp = $acct_req.GetResponse();
	$acct_resp_stream = New-Object System.IO.StreamReader($acct_resp.GetResponseStream());
	$acct_data = $acct_resp_stream.ReadToEnd();
	
	return $acct_data;
}

# Gets the specified report data, using the authorization token generated above.
function getReportData([string]$token){

	[string]$rep_url = "https://www.google.com/analytics/feeds/data?";
	[string]$rep_header = "Authorization: GoogleLogin Auth="+$auth_token;
	[string]$rep_query = "ids=ga:12380762&dimensions=ga:browser,ga:browserVersion&metrics=ga:pageviews,ga:visits&start-date=2009-03-01&end-date=2009-03-16";
	[string]$data = "";
	
	trap [Exception] { Write-Host "An error occurred in: " $MyInvocation.InvocationName 
					   Write-Host $_; break; };
	
	$rep = [System.Net.WebRequest]::Create($rep_url+$rep_query);
	$rep.Headers.Add($rep_header);
	
	$rep_resp = $rep.GetResponse();
	$rep_resp_stream = New-Object System.IO.StreamReader($rep_resp.GetResponseStream());
	$data = $rep_resp_stream.ReadToEnd();

	return $data;
}

# do it
&{

	# it seems that when you trap an exception inside a function, it throws the 
	# exception up to the calling function, making it not possible to exit 
	# directly from the script (!?).  therefore, this trap catches the exception
	#  again and exits.
	trap [Exception] { exit 1; };
	
	$auth_token = getAuthToken;
	
	if ($print_token -eq $true){
		Write-Host "---------------- token ------------------";
		Write-Host $auth_token;
		Write-Host "-----------------------------------------";
	}
	
	if ($accounts -eq $true){
		[xml]$acct_xml = getAccountData($auth_token);
		$acct_xml.Save("c:\Documents and Settings\$env:username\Desktop\accounts.xml");
	}
	
	if ($report -eq $true){
		[xml]$report_xml = getReportData($auth_token);
		$report_xml.Save("c:\Documents and Settings\$env:username\Desktop\report.xml");
	}
	
} # end

