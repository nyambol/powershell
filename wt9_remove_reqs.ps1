# $Id: wt9_remove_reqs.ps1,v 1.1 2011/12/21 10:45:09 powem Exp $
# Last Modified: $Date: 2011/12/21 10:45:09 $
# Michael Powe, WebTrends EPS

# Remove all roles and role services installed for WebTrends
# Based on the WebTrends documentation of required roles/services

$installed = @()
Get-WindowsFeature | %{if ($_.Installed){$installed += $_.DisplayName}}

# officially required, per WebTrends documentation
$required = (
"Application Server", "Web Server (IIS)", ".NET Framework 3.5.1", "Web Server (IIS) Support",
"Windows Process Activation Service Support", "HTTP Activation", "Message Queuing Activation",
"Web Server (IIS)", "Web Server", "Common HTTP Features", "Static Content", "Default Document", "Directory Browsing", "HTTP Errors", "HTTP Redirection",
"Application Development", "ASP.NET", ".NET Extensibility", "ISAPI Extensions", "ISAPI Filters",
"Health and Diagnostics", "HTTP Logging", "Logging Tools", "Request Monitor", "Tracing",
"Security", "Basic Authentication", "Windows Authentication", "Digest Authentication", "Client Certificate Mapping Authentication",
"IIS Client Certificate Mapping Authentication", "URL Authorization", "Request Filtering", "IP and Domain Restrictions",
"Management Tools", "IIS Management Console", "IIS Management Scripts and Tools",
"Management Service", "IIS 6 Management Compatibility", "IIS 6 Metabase Compatibility", "IIS 6 WMI Compatibility", 
"IIS 6 Scripting Tools", "IIS 6 Management Console"
 )
 
$roles = ("Application-Server", "Web-Server")

foreach ($r in $roles) {
	Remove-WindowsFeature -Name $r
}

# ------------- end ------------- #