param (
	[Parameter(Mandatory=$True)]
	$GlobalsFilePath
)

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE FUNCTIONS & VARIABLES
. C:\Configure_AS_WEB\SpecializeTemplate\functions.ps1
. $GlobalsFilePath

$drive = gwmi win32_volume -Filter "Label = 'Temp'"
if($drive)
{
    Write-Host ("Setting temp drive letter to T")
	$drive.DriveLetter = 'T:'
	$drive.Put() | Out-Null
}

if ($GLOBAL_DONETPARAM) {
	Write-Host ("--------------------------- Running the netparam tool ---------------------------")
	Write-Host ("Extracting the silent installer...")
	D:\APPS\EDP\Program\NetParamTool\NetParamTool.exe -extract_all:"D:\APPS\EDP\Program\NetParamTool" | Out-Null
	pushd D:\APPS\EDP\Program\NetParamTool\Disk1
	Pause("NetParam is ready, press a key to run the configuration")
	Write-Host ("NetParam is running in silent mode, please wait....")
	D:\APPS\EDP\Program\NetParamTool\Disk1\NetParamToolSilent.exe "D:\APPS\EDP\Program\uninst\NetworkParameterTool.log" NEW_IP=$GLOBAL_NETWORK_IP NEW_COMPUTERNAME=$GLOBAL_COMPUTERNAME LDAPSECURE | Out-Null
	notepad D:\APPS\EDP\Program\uninst\NetworkParameterTool.log
	notepad D:\APPS\EDP\Program\Web\capabilities.xml
	popd
	Pause
	Write-Host ("")
}
else { Write-Host ("Ignoring netparam") -foreground "yellow"}

if ($GLOBAL_DISABLE_ESKER_SERVICES) {
	Write-Host ("--------------------------- Esker Services : StartupMode to Disabled ---------------------------")
	foreach($service in $GLOBAL_SERVICES_TO_DISABLE) {
		Set-Service $service -StartupType Disabled	
	}
	Write-Host ("")
	Pause
}
else { Write-Host ("Ignoring Section : Disable Esker Services") -foreground "yellow"}

if ($GLOBAL_START_ESKER_SERVICES) {
	# [VALIDATED on PS2.0] Starting the services
	Write-Host ("--------------------------- Esker Services :StartupMode to Auto or Delayed Auto and Starting ---------------------------")
	foreach($service in $GLOBAL_SERVICES_TO_START) {
		Set-Service $service -StartupType Automatic
		Start-Service $service
	}	
    foreach($service in $GLOBAL_SERVICES_TO_DELAY_START) {
		sc.exe config $service start= delayed-auto
		Start-Service $service
	}
	Write-Host ("")
	Pause
}
else { Write-Host ("Ignoring Section : Start Esker Services") -foreground "yellow"}
