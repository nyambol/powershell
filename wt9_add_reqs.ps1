# $Id: wt9_add_reqs.ps1,v 1.1 2011/12/21 10:43:13 powem Exp $
# Install the roles and role services required for WebTrends
#


$appRoles = ("AS-NET-Framework", "AS-Web-Support", "AS-WAS-Support", "AS-HTTP-Activation", "AS-MSMQ-Activation",
			 "Web-Mgmt-Service", "Web-Mgmt-Compat")

foreach ($app in $appRoles){
	Add-WindowsFeature $app
}
