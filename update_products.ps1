
# $Id: update_products.ps1,v 1.1 2009/01/16 14:45:56 powem Exp $
# add content to Bookspan products file to make it compliant to WebTrends requirements
# Michael Powe
# 16 January 2009

$default = "c:\Documents and Settings\powem\Desktop\webtrends_prodSKU.CSV";
$output = "c:\Documents and Settings\powem\Desktop\products.csv";

[string]$header_line = "Product SKU,Product Name,Family,Group,Category,Sub-category,Manufacturer,Supplier,Cost,Retail,AOS";
[string]$append = ",,,,,,,,";
[string]$date = ",,`"" + (Get-Date).toString() + "`"" + $append;

$input = [System.IO.File]::OpenText($default);

Set-Content -Path $output -Value $header_line;
Add-Content -Path $output -Value $date

while ($input.Peek() -ne -1) {
	$line = $input.ReadLine();
	$line += $append;
	Add-Content -Path $output -Value $line;	
}