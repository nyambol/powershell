# Get progId from registry
# from Powershell in Action
# 10 Jan 2012

function Get-ProgID{

	param($filter = '.')
	
	$ClsIdPath = "REGISTRY::HKey_Classes_Root\clsid\*\progid"
	dir $ClsIdPath | 
	%{
		if ($_.name -match '\\ProgID$'){
			$_.GetValue("")
		}
	} |
	?{ $_ -match $filter }
}