# $Id: estimate_pages.PS1,v 1.2 2008/11/21 14:37:47 powem Exp $
# Estimate the page views in a directory of log files
# 21 November 2008

function Get-Pages{

	param([string]$path = "");

	begin {
		$global:break = $FALSE;

		if($path -eq ""){
			Throw (New-Object System.IO.DirectoryNotFoundException);
			trap [System.IO.DirectoryNotFoundException] {
				Write-Host "Error: $_";
				Write-Host "Enter a valid path to log files.";
				$global:break = $TRUE;
				continue;
			}
		} else {
			# line length in bytes
			$line_length = 750;
			# estimated percentage of log entries that are pages
			$mult = 0.20;
			# sum of pages
			$sum = 0;
			# pages in individual file
			$pages = 0;
			# log file extension
			$wildcard = "*.log";
			# log file path (root passed in as argument)
			$file_path = $path + "\" + $wildcard;
		}
	}

	process{
		if ($global:break){
			return;
		}
		foreach ($file in (gci $file_path)){
			$pages = ($file.length * $mult)/$line_length; 
			$sum += $pages; 
			write-host ("{0:N0}" -f $pages + " pages in $file");
		}
	}

	end{
		if($global:break -eq $FALSE){
			write-host ("{0:N0}" -f $sum + " pages total");
			$sum = $pages = 0;
			$file_path = $path = $null;
		}
	}
} # end Get-Pages