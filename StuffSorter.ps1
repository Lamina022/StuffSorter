<#-----------------------------------------------
Stuff Sorter
PowerShell Project
Modul 122: LB 2
-------------------------------------------------
Autor: Lisa Wüthrich
Version: 1.0
Date: 15.01.2021
-------------------------------------------------
Requirements:
 o	Sort files by filetype from a location to a given destination into the corresponding folders ordered by type
    o	Example: There's a folder with photos, music and videos. The script will create a folder for each type (photo, music, video) and copy the corresponding files there
 o	Script will write a log with each file moved where
 o	User can choose a custom source path and a custom destination
 o	Script will count, how many files have been moved
-----------------------------------------------#>

#####################
###### Defines ######
#####################

#Must be the first statement in a script (not counting comments)
param ([Bool]$NoPrompt=$false)

## Enable/Disable Logging
$logging = $true

## Enable/Disable Recursive moving of files
$is_recursive = $false

## Change these to change the default path
$uprofile = Write-Output $ENV:UserProfile
$default_source_path = $uprofile+"\Downloads"
$default_destination_path = $uprofile+"\Downloads"

## Set the default logging path
$def_log_path = $uprofile+"\Downloads\StuffSorter_Log.txt"

## Change these to check for specific file types
$document_types = ".txt", ".doc", "docx", ".html", ".htm", ".odt", ".pdf", ".xls", ".xlsx", ".ods", ".ppt", ".pptx"
$image_types    = ".jpg", ".jpeg", ".png", ".tiff", ".gif", ".eps", ".raw", ".ai", ".indd", ".svg"
$music_types    = ".mp3", ".wav", ".flac", ".wma", "aac"
$video_types    = ".mp4", ".mov", ".wmv", ".flv", ".avi", ".webm", ".mkv", ".avi", ".avchd"

## Delete the old log
if (Test-Path $def_log_path){Remove-Item $def_log_path}



##########################################
###### Defining Working Directories ######
##########################################

# Our do-while loop will loop as long as the paths are not valid ($false)
# Two flags need to be $true in order for the loop to end: "$src_path_is_valid" and "$dst_path_is_valid"
do {
    # Reset our variables
    $src_path_is_valid = $false
    $dst_path_is_valid = $false

    # Ask the user about the source path and destination
    if ($NoPrompt -eq $true) { 
		$src_input = $default_source_path
		$dst_input = $default_destination_path
		$src_path_is_valid = $true
		$dst_path_is_valid = $true
	}
    else {
        $src_input = Read-Host 'Enter the path to the files to sort (Default: '$uprofile'\Downloads)'
        $dst_input = Read-Host 'Enter the path to sort the files in (Default: '$uprofile'\Downloads)'
    

		# User pressed enter (string is $null) so take our defined default paths defined above
		if (!$src_input) { $src_input = $default_source_path }
		if (!$dst_input) { $dst_input = $default_destination_path }

		# Test if path exists using the Test-Path funtion
		$src_path_exists = Test-Path -Path $src_input
		$dst_path_exists = Test-Path -Path $dst_input

		# The Test-Path function returns either $true or $false. if its $true, the path exists, otherwise it doesn't
		# Lets check if the path exists
		if ($src_path_exists -eq $true) {
			
			# The path was valid so set a flag for our do-while loop
			$src_path_is_valid = $true

		}
		else {
			Write-Host 'Cannot find path '$src_input' because it does not exist.'
			
			# Path was not valid, lets set it to false so the loop repeats
			$src_path_is_valid = $false
		}
		
		# Do the same for the destination
		if ($dst_path_exists -eq $true) {
			$dst_path_is_valid = $true
		}
		else {
			Write-Host 'Cannot find path '$dst_input' because it does not exist.'
			$dst_path_is_valid = $false
		}

		# Show the user their entered paths and let them confirm the input if both paths are valid
		if ($src_path_is_valid -eq $true -and $dst_path_is_valid -eq $true) {
			Write-Host 'The current paths are: '
			Write-Host 'Source Path: ' $src_input
			Write-Host 'Destination Path: ' $dst_input

			# Prompt user and start again if input isn't "y"
			$confirm_input = Read-Host 'Continue? [y/n]'
			if ($confirm_input -ne 'y') { 
				$src_path_is_valid = $false
				$dst_path_is_valid = $false 
			}
		}
	}
# Notice the brackets around each validation, this is because otherwise the while loop would allow either $true/$false or $false/$false
}while(($src_path_is_valid -eq $false) -and ($dst_path_is_valid -eq $false)) # Do-While Loop END



################################
###### SortFiles Function ######
################################

## Functionality:
# Searches for given file-types in a given source and moves them to the given destination. 
# Each of these values (file-type, source, destination) can be set by params
# The function also creates a log containing the amount of file types moved, the path of the files and the destination moved to

## Parameters taken:
# - $Root (String)         [ The root/source directory with the files to sort]
# - $Dest (String)         [ The destination directory with the folders to sort the files into ]
# - $FileType (Array/List) [ A list containing all the file types to consider ]
# - $Outfile (String)      [ The destination to write the log to ]
function SortFiles {
    param(
        $Root = $src_input,
        $Dest = "",
        $FileType = @(),
        $Outfile = $def_log_path
    )
    
    # Filecount per type
    $header = @()
    
    # All the filepaths    
    $filelist = @()

    # Add to the log the destination
    $header += Write-Host 'Moving files to --> '$Dest

    # Loop through each file type given by the parameter and move them accordingly
    Foreach ($type in $FileType) {
        
        # Get our files except if its a folder
        # Check if recursivety is on or not
        if ($is_recursive -eq $true) { $get_files = Get-ChildItem $Root -Filter *$type -Recurse | ? { !$_.PSIsContainer }}
        
        # Recursive searching and moving of files is disabled
        # Here GetChildItem will fetch all the files in $Root filtered by the given extension
        # The function returns an object, which is piped through $_.PSIsContainer, which excludes all folders in $Root
        # Finally the file is moved to $Dest
        else  { $files = Get-ChildItem $Root -Filter *$type | ? { !$_.PSIsContainer }}
        
        # Add the file-type count to the log
        $header += "$type ---> $($files.Count) files"
        
        # Get each files source location from the file-list and add it to the log
        foreach ($file in $files) {
            $filelist += $file.FullName
            Move-Item -Path $file.FullName -Destination $Dest -Exclude $def_log_path
        }
    }
    #Collect to single output
    $output = @($header, $filelist)    
    if ($logging -eq $true) { $output | Add-Content $Outfile }
}



#######################################
###### Setting File-Type Folders ######
#######################################
$music_path = $dst_input+'\Music'
$doc_path = $dst_input+'\Documents'
$img_path = $dst_input+'\Photos'
$vid_path = $dst_input+'\Video'
$misc_path = $dst_input+'\Misc'



###########################################
###### Check if needed Folders exist ######
###########################################
# Check if our paths for the different categories are existing. Make also sure, that the target is a directory
if (Test-Path $music_path){}else{New-Item $music_path -ItemType "directory"}
if (Test-Path $doc_path){}else{New-Item $doc_path -ItemType "directory"}
if (Test-Path $img_path){}else{New-Item $img_path -ItemType "directory"}
if (Test-Path $vid_path){}else{New-Item $vid_path -ItemType "directory"}
if (Test-Path $misc_path){}else{New-Item $misc_path -ItemType "directory"}



######################################
###### Getting and Moving Files ######
######################################
# Call our handy function for each file group and move them to the pre-defined location
SortFiles -Dest $doc_path -FileType $document_types
SortFiles -Dest $img_path -FileType $image_types
SortFiles -Dest $music_path -FileType $music_types
SortFiles -Dest $vid_path -FileType $video_types
SortFiles -Dest $misc_path -FileType "*.*"

# Do some cleaning up...
$temp = Get-Content $misc_path'\StuffSorter_Log.txt'
Add-Content $def_log_path $temp
Remove-Item $misc_path'\StuffSorter_Log.txt'