# from http://mspowershell.blogspot.com/2008/07/locked-file-detection.html
# $Id$
# Last Modified: $Date$

function testFileLock {
    ## Attempts to open a file and trap the resulting error if the file is already open/locked
    param ([string]$filePath )
    $filelocked = $false
    $fileInfo = New-Object System.IO.FileInfo $filePath
    trap {
        Set-Variable -name locked -value $true -scope 1
        continue
    }
    $fileStream = $fileInfo.Open( [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )
    if ($fileStream) {
        $fileStream.Close()
    }
    $obj = New-Object Object
    $obj | Add-Member Noteproperty FilePath -value $filePath
    $obj | Add-Member Noteproperty IsLocked -value $filelocked
    $obj
}

$files = gci "$env:TEMP"
$locked = @()
foreach ($f in $files){
	if(testFileLock $f){
		$locked += $f
	}		
}

Write-Host "The following files are locked."
Write-Host $locked