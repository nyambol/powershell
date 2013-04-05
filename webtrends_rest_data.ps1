#region Documentation

<#
 .Synopsis
  This script file contains two functions for automation of data retrieval from the
  Webtrends REST API.

 .Description
  The Set-RestHash function is used to create a hashtable for the configuration
  data to be used to construct the API call.  
  
  The Get-RestData function is used   to construct the URL, using the configuration 
  data from the hashtable, and then retrieve the data.  The results are returned in 
  an object.  Depending on the type of data retrieved (HTML, XML, &c), you then use 
  the proper method to export it to file.

 .Example
  {powem} [104] --> $conf = Set-RestHash -f $env:USERPROFILE\Desktop\rest.conf
  {powem} [105] --> $data = Get-RestData -Start "2013m01d01" -End "2013m01d31" -Conf $conf
  {powem} [106] --> $data.Data | Set-Content -Path "$env:USERPROFILE\Desktop\test.html"

  Use the file rest.conf to populate the hashtable.  Then retrieve the data for 
  the month of January 2013 and store it in the $data object. Export the data 
  text into an HTML file.

 .Outputs
  An object with two properties, a count of the length of the data retrieved
  (Content-Length from the response) and the string data of the response.

 .Notes
  The here-string at the top of the script code illustrates the format of the 
  name/value pairs needed for the configuration.  

  Use `Get-Help .\webtrends_rest_data.ps1 -full' to read these instructions in the
  console window.  Use `Get-Help Set-RestHash -full' and `Get-Help Get-RestData -full'
  for detailed information on using the functions.

  Michael Powe, 31 January 2013
#>

$sampleConfig = @"
version = v3
profile = 27211
report = Y2PqMXEqeV6
totals = none
type = indv
measures = 0*1
format = html
user = account\\wt-user
pass = password
"@

#endregion

#region Function Definitions

function Set-RestHash{

<#
 .Synopsis
  Create a hash with the information necessary for the call to the REST API.

 .Description
  The call to the REST API requires a set of configuration data.  The function
  Get-RestData expects a hashtable with the necessary information.  This function
  can be used as a shortcut to creating that hash.

  $restConfig = @{version="v3";
				profile="21897";
				report="hGgJLBjviR6";
				type="indv";
				totals="none";
				format="html";
				measures="measures=0*1*2";
				user="acct\login";
				pass="password"}
  
  The username and password are optional.  If they are not present in the hashtable
  when it is passed into the data collection function, then the function will prompt 
  for them.  The additional option is to put the name = value pairs into a file and
  then read the file and process it into the hashtable.

 .Notes
  If you put the username into the file, you must escape the backslash, e.g. 
  "coca-cola\\wt-mpowe."  However, this escaping is not necessary if you enter the
  name at the console command prompt.

#>

	param([parameter(Mandatory=$false)] [alias("v")] $version,
		  [parameter(Mandatory=$false)] [alias("pr")] $profile,
		  [parameter(Mandatory=$false)] [alias("r")] $report,
		  [parameter(Mandatory=$false)] [alias("ty")] $type,
		  [parameter(Mandatory=$false)] [alias("to")] $totals,
		  [parameter(Mandatory=$false)] [alias("fo")] $format,
		  [parameter(Mandatory=$false)] [alias("m")] $measures,
		  [parameter(Mandatory=$false)] [alias("u","name")] $user="",
		  [parameter(Mandatory=$false)] [alias("pw","password")] $pass="",
          [parameter(Mandatory=$false)] [alias("f")] $file
		 )
	
	$restConfig = @{}
	
    if($file -ne $null){
        if ((Test-Path -Path $file) -eq $false){
            throw [System.IO.FileNotFoundException] ("Specified configuration data file [{0}] was not found." -f $file);
        }
        $data = Get-Content -Path $file;
        [string]$params = "";
        $data | %{$params += $_+"`n"};
        $restConfig = ConvertFrom-StringData -StringData $params;
    } else {
	    $restConfig.version = $version
	    $restConfig.profile = $profile
	    $restConfig.report = $report
	    $restConfig.type = $type
	    $restConfig.totals = $totals
	    $restConfig.format = $format
	    $restConfig.measures = "measures={0}" -f $measures
	    $restConfig.user = $user
	    $restConfig.pass = $pass
	}
    if($restConfig.ContainsKey("user") -and $restConfig.user.Length -eq 0){
        $restConfig.Remove("user");
    }
    if($restConfig.ContainsKey("pass") -and $restConfig.pass.Length -eq 0){
        $restConfig.Remove("pass");
    }
	return $restConfig
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

.Example
   $data = Get-RestData -Start "2013m01d01" -End "2013m01d15" -Conf $conf
    Enter the username (domain\user format): zinio\wt-mpowe
    Enter the password: *********

 The configuration hashtable does not contain the username and password and they
 are not passed in on the command line.

.Example
 $data = Get-RestData -Start "2013m01d01" -End "2013m01d15" -Conf $conf -User "zinio\wt-mpowe" -Pass "password"

 Credentials are not in the hash and are added on the command line.

.Outputs
  An object that contains the data retrieved and a count indicating the length of the data.

.Notes
  This function uses the StreamReader method ReadToEnd(), so a huge data response may break.
  The usual breakage is that the server closes the stream.  I assume that this happens 
  because the server has a built-in limit to the amount of data it will return in a single
  request. The solution is to chunk up the requests and then reassemble the chunks after
  they've all been retrieved.

  The username and password may be omitted from the hashtable, if desired.  In that case, 
  the function will prompt for them.  

  To export to an HTML file, use something like:
  $data.Data | Set-Content -Path "C:\Users\powem\Desktop\test.html"
  
  Some trivial exception handling is included, which may prevent falling into an infinite
  loop of errors if something goes wrong
#>
	param (
	[parameter(Mandatory = $true)] [string]$Start,
	[parameter(Mandatory = $true)] [string]$End,
	[parameter(Mandatory = $true)] [hashtable]$Conf,
    [parameter(Mandatory = $false)] [string]$user="",
    [parameter(Mandatory = $false)] [string]$pass="")

    begin{
        # This function cribbed from Oison Grehan, PS MVP
        function ConvertTo-PlainText( [security.securestring]$secure ) {
            $marshal = [Runtime.InteropServices.Marshal]
            return $marshal::PtrToStringAuto( $marshal::SecureStringToBSTR($secure) )
        }

	    $version = $Conf.version
	    $profile = $Conf.profile
	    $report = $Conf.report
	    $type = $Conf.type
	    $totals = $Conf.totals
	    $format = $Conf.format
	    # put in a nonsense number to include all measures
	    $measures = $Conf.measures
        
        # you must meet one of two criteria.  Either the user/pass must be in the 
        # file; or, the user/pass must be entered here.  The case in which a null
        # or empty value for the user/pass in the hashtable does not work.  Why, 
        # I don't know.        
        if(-not($Conf.ContainsKey("user")) -and $user -eq ""){
            $user = Read-Host "Enter the username (domain\user format)";
        }
        if(-not($Conf.ContainsKey("pass")) -and $pass -eq ""){
            $secure = Read-Host -AsSecureString "Enter the password";
            $pass = ConvertTo-PlainText $secure;
        }
	
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
	
        if($Conf.ContainsKey("user") -eq $false){
            $Username = $user;
        } else {
            $Username = $Conf.user;
        }
	    if($Conf.ContainsKey("pass") -eq $false){
            $Password = $pass;
        } else {
	        $Password = $Conf.pass
        }

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
	}
    process {
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
	    }
    end{
	    if ($reader -ne $null){
		    $reader.Close()
	    }
	    if ($response -ne $null){
		    $response.Close()
	    }
	
	    return $restData
    }
}
#endregion
# ------------------ end script file webtrends_rest_data.ps1 ---------------------