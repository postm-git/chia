# Powershell script to robocopy .plot files from staging directories to target directories
# Overview:
# In an infinite loop:
# - for each source directory:
# -- out of a list of destination drives, find one drive with at space for at least one .plot file
# -- are there any .plot files in the source directory? If there are, take the first file
# -- rename that file (change extension to .transfer)
# -- robocopy that one file (MOVE) to a free drive. Destination path is /plots
# -- after robocopy/move, rename .transfer back to .plot
# -- after robocopy/move of each file, once again find the drive with

# sets the powershell window title
$host.ui.RawUI.WindowTitle = "Robocopy loop"

# directories to monitor. these locations contain .plot files to robocopy/move (temporary or staging directories)
$sources = "E:\temp1\", "E:\temp2\", "E:\temp3\"

# these are drive names that we will robocopy/move to, based on which has free space
$destdrives = 'L','Y','Z','H','I','G'

# IN AN INFINITE LOOP
Do
{
	"--------------------------------------"			
	Get-Date -Format "dddd yyyy-dd-MM HH:mm"		

    # for each source directory
	Foreach ($source in $sources)
	{
	    # find which destination drive has at space for eat least one plot file (with some buffer)
	    for ($i=0; $i -lt $destdrives.length; $i++)
    	{
    		$drive = get-psdrive $destdrives[$i]
    		# approximate free space in GBytes, divided by 110 (more than enough for one k32 file)
    		$free = $drive.free/1073741824/110
    		# if there is not enough room, go check next drive
    		if ($free -lt 1.2)
    		{
    			"Drive " + $destdrives[$i] + " full!"
    		}
    		else # if there IS enough room, select this destination an exit the loop
    		{
    		    # for drive X, destination will be X:\plots
    			$dest = $destdrives[$i] + ":\plots"
    			break
    		}
    	}

    	"Using destination: $dest"
		Write-Host -NoNewline " $source to $dest`t| "

        # look at the current source directory, search for *.plot files. Take ONLY THE FIRST such file, if found
		$torename = @(Get-ChildItem $source*.plot)[0]
		# if a .plot file found here
		if ($torename)
		{
		    # rename .plot file to .transfer
			@(Get-ChildItem $source*.plot)[0] | Rename-Item -NewName {$_.Name -replace '.plot','.transfer'}
			Write-Host ""
			Write-Host "Renamed $torename"			
		}
		else # if no .plot files found
		{
			Write-Host -NoNewline "0 renamed`t| "
		}

	    # look at the current source directory, search for *.transfer files. There should be one if we just renamed one.
	    # Take ONLY ONE such .transfer file
		$tosend = @(Get-ChildItem $source*.transfer)[0]
		if ($tosend)
		{
			Write-Host "Sending $tosend"
			
			# move .transfer file from source to destination
			robocopy $source $dest /mov /j /njs /njh *.transfer

			# RENAME the destination file from .transfer back to .plot
			Get-ChildItem $dest\*.transfer | Rename-Item -NewName {$_.Name -replace '.transfer','.plot'}
		}
		else
		{
			Write-Host "0 sent"
		}
			
		Start-Sleep 1
	}

	# repeat everything after 120 seconds
	"--------------------------------------"
	"Sleeping.."
	Start-Sleep 120
} While ($true) # DO ABOVE, FOREVER