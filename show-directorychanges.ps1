# monitor a directory for changes and report them

function Show-DirectoryChanges{

param([string]$directory = ($throw "Needs a directory path to monitor."),
		[switch]$exit)

	if($exit){
		Unregister-Event $changed.Id
		Unregister-Event $created.Id
		Unregister-Event $deleted.Id
		Unregister-Event $renamed.Id
		return
	}

	$watcher = New-Object System.IO.FileSystemWatcher
	$watcher.Path = $directory
	$watcher.IncludeSubdirectories = $true
	$watcher.EnableRaisingEvents = $true

	$changed = Register-ObjectEvent $watcher "Changed" -Action {
	   write-host "Changed: $($eventArgs.FullPath)"
	}
	$created = Register-ObjectEvent $watcher "Created" -Action {
	   write-host "Created: $($eventArgs.FullPath)"
	}
	$deleted = Register-ObjectEvent $watcher "Deleted" -Action {
	   write-host "Deleted: $($eventArgs.FullPath)"
	}
	$renamed = Register-ObjectEvent $watcher "Renamed" -Action {
	   write-host "Renamed: $($eventArgs.FullPath)"
	}
	
	
}