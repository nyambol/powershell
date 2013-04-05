# generate profile list from web services and 
# get profile metadata
# $Id: get_rest_data.ps1,v 1.1 2012/03/09 16:04:47 powem Exp $
#
# Last Modified: $Date: 2012/03/09 16:04:47 $
# Michael Powe
# WebTrends

function ConvertTo-Base64($string) {
   $bytes  = [System.Text.Encoding]::UTF8.GetBytes($string);
   $encoded = [System.Convert]::ToBase64String($bytes); 

   return $encoded;
}


$password = "mpW3btrends!"
$user = "mpowe"
$url = "http://api.webtrends.scee.net/v2_0/ReportService/profiles/?format=xml2"

$authHeader = "$user:$password"
$authHeader64 = Convertto-Base64 $authHeader
$credential = New-Object System.Net.NetworkCredential($user, $password)

$request = [System.Net.WebRequest]::Create($url)
$request.Credentials = $credential

# $request.Headers.Add("Authorization","Basic " + $authHeader)

# $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force

# $credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

[xml] $data = $request.GetResponse()
