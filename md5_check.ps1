# MD5 check script
# $Id$


<#
.Synopsis 
 Find and optional verify the MD5 value for a file.

.Description
 Run the MD5 verification tool to find the value for a given file.  Optionally, pass in the known or assumed value for the file and determine if the two values match. If the MD5 string is not passed into the script, the script will just return the file's value.

.Parameter Target
 The full path to the file to be checked.

.Parameter md5
 The MD5 string for the target file.  If this optional value is supplied, the script will verify the file.  

.Notes
 The script uses the free utility provided by Microsoft to find the MD5 value of the file.

#>
function Verify-MD5{

    param(
        [parameter(Mandatory=$true)]
		      [alias("t")]
		      [string]$target,
        [parameter(Mandatory=$false)]
              [alias("m")]
              [string]$md5
    )

    $checker = "C:\fciv\fciv.exe";

    if(-not (Test-Path -Path $checker)) {
        throw [System.IO.FileNotFoundException] "MD5 verification tool not found.  Check your path.";
    }

    if(-not (Test-Path -Path $target)) {
        throw [System.IO.FileNotFoundException] "File to be verified not found.  Check your path.";
    }

    $value = (Invoke-Expression -Command ($checker + " " + $target));

    $md = $value | ?{-not($_.StartsWith("/"))} | %{$_.Split(" ")[0]};

    if($md5){
        if($md -eq $md5){
            Write-Host ("MD5 verification passed.`n`t{0} matches {1}" -f $md, $md5);
        } elseif ($md -ne $md5){
            Write-Host ("MD5 verification FAILED.`n`t{0} does not match {1}" -f $md, $md5);
        }
    } else {
        Write-Host $md;
    }
}