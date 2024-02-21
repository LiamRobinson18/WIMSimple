
<#PSScriptInfo

.VERSION 1.0

.GUID 0ace940e-e8f4-4dc3-91f0-7bf35a3d283e

.AUTHOR Liam Robinson

.COMPANYNAME

.COPYRIGHT All rights reserved. - Liam Robinson. This script should not be republished in any way, shape or form without written consent.

.TAGS Windows11 WindowsImage Windows OSD

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 WIMSimple for W11. Streamline the deployment of Windows 11 by removing unwanted apps, indexes and adding drivers to your Windows 11 Image file using one handy script. 

#> 

Param()


Function Check-RunAsAdministrator()
{
  #Get current user context
  $CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  
  #Check user is running the script is member of Administrator Group
  if($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
  {
       Write-Output "Script is running with Administrator privileges!"
  }
  else
    {
       Write-Output "Script is running without Administrator privileges, this is needed to launch DISM."
       Write-Output "We will now restart and launch as Admin.."
       
       Start-Sleep -Seconds 5
       #Create a new Elevated process to Start PowerShell
       $ElevatedProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
 
       # Specify the current script path and name as a parameter
       $ElevatedProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
 
       #Set the Process to elevated
       $ElevatedProcess.Verb = "runas"
 
       #Start the new elevated process
       [System.Diagnostics.Process]::Start($ElevatedProcess)
 
       #Exit from the current, unelevated, process
       Exit
 
    }
}
 
#Check Script is running with Elevated Privileges
Check-RunAsAdministrator
 
#Begin Script

Write-Output @"

░██╗░░░░░░░██╗██╗███╗░░░███╗░██████╗██╗███╗░░░███╗██████╗░██╗░░░░░███████╗
░██║░░██╗░░██║██║████╗░████║██╔════╝██║████╗░████║██╔══██╗██║░░░░░██╔════╝
░╚██╗████╗██╔╝██║██╔████╔██║╚█████╗░██║██╔████╔██║██████╔╝██║░░░░░█████╗░░
░░████╔═████║░██║██║╚██╔╝██║░╚═══██╗██║██║╚██╔╝██║██╔═══╝░██║░░░░░██╔══╝░░
░░╚██╔╝░╚██╔╝░██║██║░╚═╝░██║██████╔╝██║██║░╚═╝░██║██║░░░░░███████╗███████╗
░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═════╝░╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░╚══════╝╚══════╝

█▄▄ █▄█   ▄▄   █░░ █ ▄▀█ █▀▄▀█   █▀█ █▀█ █▄▄ █ █▄░█ █▀ █▀█ █▄░█  
█▄█ ░█░   ░░   █▄▄ █ █▀█ █░▀░█   █▀▄ █▄█ █▄█ █ █░▀█ ▄█ █▄█ █░▀█  
"@

###########################
###########################
# Create working directory
###########################
###########################
$WimDir = "C:\WIMSIMPLE\WIM"
$StageDir = "C:\WIMSIMPLE\STAGING"

Write-Output ""
Write-Output "We will now try to create an app directory in C:\WIMSIMPLE\"
Start-Sleep -Seconds 3

Write-Output ""

## Creat WIM Folder

if (!(Test-Path $WimDir)) {
    New-Item -ItemType Directory -Path $WimDir | Out-Null
    Write-Output "$WimDir created successfully."
} else {
    Write-Output "$Wimdir already exists."
}

Write-Output ""
## Create Staging Folder

if (!(Test-Path $StageDir)) {
    New-Item -ItemType Directory -Path $StageDir | Out-Null
    Write-Output "$StageDir created successfully."
} else {
    Write-Output "$StageDir already exists."
}

Write-Output ""
Write-Output "Importing DISM Module"
Import-Module -Name Dism

###########################
###########################
##### Choose ISO File #####
###########################
###########################

Write-Output ""
Write-Output "You now need to select your W11 ISO File"
Write-Output ""
pause
# Function to open file browser dialog
function Open-FileBrowserDialog {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $fileBrowserDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileBrowserDialog.Filter = "ISO files (*.iso)|*.iso"
    $fileBrowserDialog.Title = "Select ISO File"
    $fileBrowserDialog.ShowDialog() | Out-Null

    return $fileBrowserDialog.FileName
}

# Prompt until a file is selected
do {
    $selectedFile = Open-FileBrowserDialog
    if ([string]::IsNullOrWhiteSpace($selectedFile)) {
        Write-Output "No file selected. Please try again."
        pause
    }
} while ([string]::IsNullOrWhiteSpace($selectedFile))

Write-Output "Selected file: $selectedFile"

###########################
###########################
###########################
###########################

$iso = $selectedFile

# Extract just the filename without the directory path
$ISOName = Split-Path $iso -Leaf

Write-Output ""
Write-Output "Mounting ISO - $ISOName..."



##Mount Selected File
$Mount = Mount-DiskImage -ImagePath $iso

## Get Drive Letter 

$driveLetter = ($Mount | Get-Volume).DriveLetter
Write-Output ""
Write-Output "ISO mounted to $driveletter"
Write-Output ""
Write-Output "Begining to extract WIM File from ISO"
Write-Output ""

######## Create directory based on current date and time (To avoid wim files clashing) ######
## Get current date and time ##

$currentDateTime = Get-Date

## Format the date and time as a timestamp ##

$timestamp = $currentDateTime.ToString("dd-MM-yyyy_HHmmss")

## Create Unique Directory based on time

New-Item -ItemType Directory -Force -Path C:\WIMSIMPLE\WIM\$timestamp | Out-Null

$dest = $WimDir + "\" + $timestamp 

##import copying tool and copy from ISO to WIM Folder ##

Import-Module BitsTransfer
Start-BitsTransfer -Source "${driveLetter}:\sources\install.wim" -Destination $dest -Description "Extracting WIM file to $dest" -DisplayName "Extracting WIM file from ISO"

# Remove Read-Only Attribute
Set-ItemProperty -Path $dest\install.wim -Name IsReadOnly -Value $false

##Dismount ISO File

Write-Output "Attempting to dismount ISO"
Write-Output ""

try {
    # Unmount the disk image
    Dismount-DiskImage -ImagePath $iso -ErrorAction Stop | Out-Null
    
    # If no error occurred, the unmounting was successful
    Write-Output "ISO unmounting was successful."
} catch {
    # If an error occurred, the unmounting failed
    Write-Output "Disk image unmounting failed. Error: $_"
}


Write-Output ""
Write-Output "Checking WIM File for Multiple Operating Systems"
Write-Output ""

## Get info from mounted image
Start-Sleep -Seconds 2

# Get the image indexes from the WIM file
$imageInfo = Get-WindowsImage -ImagePath $dest\install.wim

# Specify Wim Path
$OriginalWimPath = $dest + "\install.wim"
$NewWimPath = $dest + "\modified" + "\install.wim"

# Display available image indexes to the user
Write-Output "Available Image Indexes:"
Write-Output ""
for ($i = 0; $i -lt $imageInfo.Count; $i++) {
    $index = $i + 1  # Adjust index to start from 1
    Write-Output "$index. $($imageInfo[$i].ImageName)"
}


# Prompt the user to select an image index
do {
    Write-Output ""
    $selectedIndex = Read-Host "Enter the index number of the image you want to mount"
} while (-not ([int]::TryParse($selectedIndex, [ref]$null)))

$selectedIndex = [int]$selectedIndex

if ($selectedIndex -ge 0 -and $selectedIndex -lt $imageInfo.Count) {
    Write-Output ""
    Write-Output "Checking $StageDir for already mounted images, we will remove them if found"
    Write-Output ""
    # Get the contents of the mount directory
    $contents = Get-ChildItem -Path $StageDir

    # Check if the directory is empty
    if ($contents.Count -eq 0) {
        Write-Output ""
        Write-Output "No image mounted..continuing"
        Write-Output ""
    } else {
        Write-Output ""
        Write-Output "The staging directory already contains a mounted image."
        Write-Output ""
        Write-Output "Attempting to unmount image"
        Dismount-WindowsImage -Path $StageDir -Discard
        #dism /Unmount-Wim /Mountdir:$StageDir /discard
        Write-Output ""
    }

    # Prompt the user if they want to copy the selected index
    do {
        $copySelectedOnly = Read-Host "Do you want to reduce WIM filesize by removing all other indexes? (Y/N)"
    } while ($copySelectedOnly -notmatch "^[yn]$")

    if ($copySelectedOnly -eq "Y" -or $copySelectedOnly -eq "y") {
        # Copy selected index to a new WIM file
        $Moddest = $Dest + "\MODIFIED"
        $wimpath = $NewWimPath
        New-Item -ItemType Directory -Path $Moddest | Out-Null
        Write-Output ""
        Write-Output "Exporting index $selectedIndex to new WIM File - $NewWimPath"
        Write-Output ""
        Export-WindowsImage -SourceImagePath $OriginalWimPath -SourceIndex $selectedIndex -DestinationImagePath $NewWimPath

        Write-Output "Selected index copied to $NewWimPath"
        Write-Output ""
        Write-Output "Mounting WIM File - $NewWimPath"
        # Mount the new WIM file
        Mount-WindowsImage -ImagePath $NewWimPath -Index 1 -Path $StageDir

        # Display the image name of the selected index
        Write-Output "Mounted image: $($imageInfo[$selectedIndex - 1].ImageName)"
    } else {
        # Mount the original WIM file
        $wimpath = $OriginalWimPath
        Write-Output ""
        Write-Output "Mounting WIM File - $OriginalWimPath"
        Mount-WindowsImage -ImagePath $OriginalWimPath -Index $selectedIndex -Path $StageDir

        # Display the image name of the selected index
        Write-Output "Mounted image: $($imageInfo[$selectedIndex - 1].ImageName)"
    }

    if ($?) {
        Write-Output "Image mounted successfully at $StageDir"
    } else {
        Write-Output "There was an error mounting the image. Please check the staging folder and try again."
        Write-Output "You can use 'Get-WindowsImage -Mounted' CMDlet to check if an image is already mounted."
        Write-Output "Use 'dism /Unmount-Wim /Mountdir:C:\WIMSIMPLE\STAGING /discard' to manually unmount fully and try the script again."
    }
} else {
    Write-Output "Invalid index number. Please enter a valid index number."
}

###################-------------------########################
###################    REMOVE APPS    ########################
###################-------------------########################

# Function to remove provisioned app by name
function Remove-ProvisionedAppByName {
    param(
        [string[]]$Patterns,
        [string]$MountPath,
        [array]$ProvisionedApps
    )
    foreach ($Pattern in $Patterns) {
        foreach ($App in $ProvisionedApps) {
            if ($App.DisplayName -like "*$Pattern*") {
                Write-Output "Removing $($App.DisplayName)..."
                Remove-AppxProvisionedPackage -Path $MountPath -PackageName $App.PackageName | Out-Null
            }
        }
    }
}

# Function to list provisioned apps and ask the user if they want to remove them
function Remove-ProvisionedAppsInteractively {
    param(
        [string]$MountPath,
        [array]$ProvisionedApps
    )
    foreach ($App in $ProvisionedApps) {
        $Response = Read-Host "Remove $($App.DisplayName)? (Y/N)"
        if ($Response -eq 'Y' -or $Response -eq 'y') {
            Write-Output "Removing $($App.DisplayName)..."
            Remove-AppxProvisionedPackage -Path $MountPath -PackageName $App.PackageName | out-null
        }
    }
}

# Get a list of provisioned apps
$ProvisionedApps = Get-AppxProvisionedPackage -Path $StageDir

# Offer user options
$validOption = $false
while (-not $validOption) {
    Write-Output ""
    Write-Output "Remove unwanted apps"
    Write-Output ""
    Write-Output "1. Optimise for Education - will automatically remove a pre-set list of apps (see website for details)"
    Write-Output "2. Manually remove each app 1-by-1"
    Write-Output "3. Don't remove any apps"
    Write-Output ""
    $Option = Read-Host "Choose an Option."
    Write-Output ""

    switch ($Option) {
        1 {
            $validOption = $true
            $Patterns = @("Microsoft.WindowsMaps", "Microsoft.Xbox", "Microsoft.Bing", "MicrosoftCorporationII.QuickAssist" , "MicrosoftCorporationII.MicrosoftFamily", "Microsoft.ZuneVideo", "Microsoft.ZuneMusic", "Microsoft.YourPhone", "Microsoft.WindowsTerminal", "Microsoft.WindowsAlarms", "Microsoft.WindowsFeedbackHub", "Microsoft.Todos", "Microsoft.PowerAutomateDesktop", "Microsoft.People", "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.Getstarted", "Microsoft.GetHelp", "Microsoft.GamingApp")  # Add multiple patterns here
            Remove-ProvisionedAppByName -Patterns $Patterns -MountPath $StageDir -ProvisionedApps $ProvisionedApps
            break
        }
        2 {
            $validOption = $true
            Remove-ProvisionedAppsInteractively -MountPath $StageDir -ProvisionedApps $ProvisionedApps
            break
        }
        3 {
            $validOption = $true
            break
        }
        default {
            Write-Output "Invalid option selected. Please select either 1 or 2."
            break
        }
    }
}

Write-Output ""
Write-Output "The Following apps still remain on the WIM file"
Write-Output ""

# Get information about Appx packages from the Windows image
$ProvisionedApps = Get-AppxProvisionedPackage -Path $StageDir

# Display the information in a clear and readable format
$ProvisionedApps | Format-Table -AutoSize DisplayName, PackageName

Write-Output ""
do {
    $RemoveOption = Read-Host "Choose an option:`n1. Remove more apps`n2. Don't remove any more apps`n"

    if ($RemoveOption -ne "1" -and $RemoveOption -ne "2") {
        Write-Output "Invalid option selected. Please choose either '1' or '2'."
        Write-Output ""
    }
} until ($RemoveOption -eq "1" -or $RemoveOption -eq "2")

switch ($RemoveOption) {
    1 {
        Remove-ProvisionedAppsInteractively -MountPath $StageDir -ProvisionedApps $ProvisionedApps
        break
    }
    2 {
        # Continue without removing anymore apps
        break
    }
}

Write-Output ""
do {
    $DriverOption = Read-Host "Do You Want to inject drivers to the image?:`n1. Inject drivers`n2. Do not add drivers.`n"

    if ($DriverOption -ne "1" -and $DriverOption -ne "2") {
        Write-Output "Invalid option selected. Please choose either '1' or '2'."
        Write-Output ""
    }
} until ($DriverOption -eq "1" -or $DriverOption -eq "2")

switch ($DriverOption) {
    1 { 
    
        # Load Windows Forms assembly
        Add-Type -AssemblyName System.Windows.Forms

        # Function to validate if the directory contains driver files
        function Validate-DriversFolder {
            param (
                [string]$folderPath
            )

            # Check if the selected directory contains driver files
            if (Test-Path (Join-Path $folderPath "*") -PathType Leaf) {
                return $true
            }
            else {
                return $false
            }
        }

        # Create open file dialog
        $openFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $openFileDialog.Description = "Select the directory containing the drivers"
        $openFileDialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
        $openFileDialog.ShowNewFolderButton = $false

        # Prompt user to select a directory containing drivers
        $selectedFolder = $null
        while (-not $selectedFolder) {
            # Show the open file dialog and check if user selects a directory
            if ($openFileDialog.ShowDialog() -eq 'OK') {
                $selectedFolder = $openFileDialog.SelectedPath
            }
            else {
                # User cancelled the dialog
                $choice = [System.Windows.Forms.MessageBox]::Show("Do you want to cancel injecting drivers?", "Cancel?", "YesNo", "Question")
                if ($choice -eq "Yes") {
                    break
                }
            }
        }

        # Validate the selected folder for drivers
        if (Validate-DriversFolder -folderPath $selectedFolder) {

            # Add drivers to the mounted WIM
            Write-Output "Injecting Selected Driver Files. This could take a while."
            Write-Output ""
            Add-WindowsDriver -Path $StageDir -Driver $selectedFolder -Recurse -Verbose | Out-Null
            Write-Output ""
            Write-Output "Finished adding drivers to image.."
            Write-Output ""
            break

        } else {
            Write-Output "The selected directory does not contain any driver files."
        }
    }
    2 {
        Write-Output "Skipping importing drivers..."
        Write-Output ""
        break
    }
}


try {
    Write-Output ""
    Write-Output "Attempting to save & dismount image..This could take a while"
    Write-Output ""
    
    # Attempt to dismount the Windows image
    Dismount-WindowsImage -Path $StageDir -Save

    # If successful, provide feedback
    Write-Output ""
    Write-Output "Image successfully dismounted and saved."
    Write-Output "Your updated WIM file is located at $wimpath"
    Write-Output ""
} catch {
    # If an error occurs, provide more detailed error information
    $errorMessage = $_.Exception.Message
    Write-Output "Error occurred while dismounting the image: $errorMessage"
}

Write-Output "Thank you for using WIMSimple...Exiting" 
Pause
Exit
