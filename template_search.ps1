#find a set of report guids in the webtrends templates.  
#since the templates contain a number of matches, for the chapter,
#graphs and tables, strip out everything except the chapter.

C:\wtdata\storage\config\wtm_wtx\report_templates
{wtservice} [21]-->  $guids
Wn1jvsPfuT6
Wn1jvsPfuT6
Wn1jvsPfuT6

$guids = ("Wn1jvsPfuT6","Wn1jvsPfuT6","Wn1jvsPfuT6")

gci -Recurse -Filter *.wct | %{ foreach($r in $guids){Select-String -Path $_.FullName -Pattern $r | ?{$_.Line -match "Chapter"}}}

C:\wtdata\storage\config\wtm_wtx\report_templates
{wtservice} [23]-->  gci -Recurse -Filter *.wct | %{ foreach($r in $guids){Select-String -Path $_.FullName -Pattern $r | ?{$_.Line -match "Chapter"}}}

rcent\flrdacbkoji.wct:7556:pageid = dynamictablesWn1jvsPfuT6Chapter1
rcent\flrdacbkoji.wct:7556:pageid = dynamictablesWn1jvsPfuT6Chapter1
rcent\flrdacbkoji.wct:7556:pageid = dynamictablesWn1jvsPfuT6Chapter1

Get-Child-Item -Recurse -Filter *.wct | 
Foreach-Object { 
    foreach($r in $guids){
        Select-String -Path $_.FullName -Pattern $r | 
        Where-Object {
            $_.Line -match "Chapter"
        }
    }
}
