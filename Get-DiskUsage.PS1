##############################################################################
##
## Get-DiskUsage.ps1
##
## Retrieve information about disk usage in the current directory and all
## subdirectories. If you specify the -IncludeSubdirectories flag, this
## script accounts for the size of subdirectories in the size of a directory.
##
## ie:
##
##  PS >Get-DiskUsage
##  PS >Get-DiskUsage -IncludeSubdirectories
##
## Taken from Powershell Cookbook
## 2008-08-27
##
##############################################################################

param(
  [switch] $includeSubdirectories
  )

## If they specify the -IncludeSubdirectories flag, then we want to account
## for all subdirectories in the size of each directory
if($includeSubdirectories)
{
    Get-ChildItem | Where-Object { $_.PsIsContainer } |
        Select-Object Name,
            @{ Name="Size";
            Expression={ "{0:N2}" -f (($_ | Get-ChildItem -Recurse |
                Measure-Object -Sum Length).Sum + 0)/1024 } }
}
## Otherwise, we just find all directories below the current directory,
## and determine their size 
else 
{
    Get-ChildItem -Recurse | Where-Object { $_.PsIsContainer } |
        Select-Object FullName,
            @{ Name="Size";
            Expression={ (($_ | Get-ChildItem |
                Measure-Object -Sum Length).Sum + 0)/1024 } };
}
