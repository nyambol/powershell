 # $Id: logfile_find.PS1,v 1.1.1.1 2008/08/28 00:58:34 powem Exp $
 # Purpose:  To pull the values of selected field from a log file
 # $Date: 2008/08/28 00:58:34 $
 
 
 function usage{
 
 	if ($Args.Length -lt 1)
	{
		$Host.UI.WriteLine("Need the name of a file.");
		$Host.UI.WriteLine("Usage: " + $0 + " <filename>");
	}
 
 }
 
 usage;
 