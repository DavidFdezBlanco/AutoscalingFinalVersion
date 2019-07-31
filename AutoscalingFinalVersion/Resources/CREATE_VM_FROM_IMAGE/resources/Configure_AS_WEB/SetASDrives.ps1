param
(
	# Disks names. 
	$EDPDiskName = "EDP",
	$TempAzureDiskName = "Temporary Storage",
	$TempProductDiskName = "Temp"
)

# ---- Page File Methods ----
function GetPageFile()
{
	$PageFileInfo = Get-WmiObject -Query "select * from Win32_PageFileSetting"
	Write-Host "Current Page File is"$PageFileInfo.Name
	return $PageFileInfo.Name.SubString(0,1) # returns 'C' or 'D' or 'E'
}

function MovePageFile(
	[string] $Destination
)
{
	$DestFile = $Destination+":\pagefile.sys"
	Write-Host "Move Page File to "$DestFile
	
	$PageFileInfo = Get-WmiObject -Query "select * from Win32_PageFileSetting"
	$PageFileInfo.Delete()
	
	Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name=$DestFile;InitialSize = 0; MaximumSize = 0}
}

# ---- Disk Methods ----
function ChangeDiskLetter(
	[string] $Source,
	[string] $Destination
)
{
	Set-Partition -DriveLetter $Source -NewDriveLetter $Destination
}

function GetDiskLetter(
	[string] $Name
)
{
	$Volume = Get-Volume | Where {$_.FileSystemLabel -eq $Name}
	return $($Volume.DriveLetter)
}

function CheckDiskName(
	[string] $Letter,
	[string] $Name
)
{	
	return ((GetDiskLetter -Name $Name) -eq $Letter)
}


# ---- Other Methods ----
function Reboot()
{
	Write-Host "Reboot..."
	shutdown /r /f /t 0
}

# ---- Main ----
$PageFileDrive = GetPageFile
switch ($PageFileDrive){
	'C'{
		$EDPDiskLetter = GetDiskLetter -Name $EDPDiskName
		$TempAzureDiskLetter = GetDiskLetter -Name $TempAzureDiskName
		$TempProductDiskLetter = GetDiskLetter -Name $TempProductDiskName
		
		ChangeDiskLetter -Source $TempAzureDiskLetter -Destination "Y" # Temp Letter to switch
		ChangeDiskLetter -Source $TempProductDiskLetter -Destination "T"
		ChangeDiskLetter -Source $EDPDiskLetter -Destination "D"
		ChangeDiskLetter -Source "Y" -Destination "E"
		MovePageFile -Destination "E"
		Reboot
		break
	}
	'E'{
		if(CheckDiskName -Letter "D" -Name $EDPDiskName){
			if(CheckDiskName -Letter "E" -Name $TempAzureDiskName){
				if(CheckDiskName -Letter "T" -Name $TempProductDiskName){
					#Everything is awesome !
					Write-Host "Configuration is good ! Nothing to do"
					return 0
				}
				else{
					Write-Error "Oops T Drive exists but is not named $TempProductDiskName. That behaviour is not expected. Please connect to the VM to check."
					return 1
				}
			}
			else{
				Write-Error "Oops E Drive exists but is not named $TempAzureDiskName. That behaviour is not expected. Please connect to the VM to check."
				return 1
			}
		}
		else{
			Write-Error "Oops D Drive exists but is not named $EDPDiskName. That behaviour is not expected. Please connect to the VM to check."
			return 1
		}
	}
	'D'{ 
		MovePageFile -Destination "C"
		Reboot
		break
	}
	'T'{ 
		MovePageFile -Destination "C"
		Reboot
		break
	}
	default { Write-Error "Oops ! No case for PageFile: $PageFileDrive"}
}