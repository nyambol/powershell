function Format-Case{
<#
.Synopsis
 Format a given string into upper, lower, or proper case.

.Description
 Specify a string and optionally, -U for upper case or -L for lower case.  Default behavior is to proper case the string.

.Parameter Text
 The string to be modified.

.Parameter L
 Optional switch to lower-case the string.

.Parameter U
 Optional switch to upper-case the string.

#>

    param(
        [parameter(Mandatory=$true)] 
        [string]$Text,
        [parameter(Mandatory=$false)]
        [switch]$L,
        [parameter(Mandatory=$false)]
        [switch]$U
    )
    
    begin{

        [string]$processed = "";
    }

    process{
            if($L) 
            { 
                $processed = (Get-Culture).TextInfo.ToLower($Text);
            }
            elseif($U) 
            {
                $processed = (Get-Culture).TextInfo.ToUpper($Text);
            }
            else 
            {
                $processed = (Get-Culture).TextInfo.ToTitleCase($Text);
            }
    }
    end{
    
        return $processed;
    }
}