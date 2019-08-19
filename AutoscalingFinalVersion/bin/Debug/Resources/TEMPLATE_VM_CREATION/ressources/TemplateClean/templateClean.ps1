cd D:/TemplateClean-XXXSPRITNXXX

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE FUNCTIONS & VARIABLES
. ./functions.ps1
. ./globals.ps1

# [VALIDATED on PS2.0] Showing files extension
Write-Host ("--------------------------- Showing files extension ----------------------")
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key HideFileExt 0
Write-Host ("")
Pause

if ($GLOBAL_CLEAR_WINDOWS_EVENTLOG) {
	Write-Host ("--------------------------- Clearing Windows EventLog ----------------------")
	clear-eventlog -log application, system
	Write-Host ("")
	Pause
}
else { Write-Host ("Ignoring Windows Event Log Purge") -foreground "yellow"}

if ($GLOBAL_STOP_ESKER_SERVICES) {
	# [VALIDATED on PS2.0] Stopping the services
	Write-Host ("--------------------------- Esker Services : Stopping + StartupMode to Manual ---------------------------")
	foreach($service in $GLOBAL_SERVICES_TO_STOP) {
		Stop-Service $service 
		Set-Service $service -StartupType Manual
	}
	Write-Host ("")
	Pause
}
else { Write-Host ("Ignoring Esker Services stopping") -foreground "yellow"}

if ($GLOBAL_PURGE_EDP_FILES) {
	# [VALIDATED on PS2.0]  Deleting & Copying files
	Write-Host ("--------------------------- Deleting & Copying files ---------------------------")
	Write-Host ("Deleting localcounters.cache...")
	del $GLOBAL_TempFolder"localcounters.cache"
	Write-Host ("Deleting esklogs...")
	del "C:\Program Files (x86)\Common Files\Esker Shared\EskLog\LogFiles\esklog.*"
	Write-Host ("Cleaning mirroring folder...")
	Remove-Item "D:\APPS\Mirroring\*" -recurse
	Write-Host ("Cleaning triggerData folder...")
	Remove-Item "D:\APPS\triggerdata\*" -recurse
	Write-Host ("Cleaning Temp folder...")
	Remove-Item $GLOBAL_TempFolder"\*" -recurse
	Write-Host ("Cleaning DocMgr Temp...")
	Remove-Item $GLOBAL_DocMgrTemp"*" -recurse
	Write-Host ("Updating ldap32.ocx...")
	copy "C:\Program Files (x86)\Common Files\Esker Shared\ldap32.ocx" "D:\APPS\edp\Program\NetParamTool"
	Write-Host ("")
	Pause
}

if ($GLOBAL_DONETPARAM) {
	Write-Host ("--------------------------- Running the netparam tool ---------------------------")
	Write-Host ("Extracting the silent installer...")
	D:\APPS\EDP\Program\NetParamTool\NetParamTool.exe -extract_all:"D:\APPS\EDP\Program\NetParamTool" | Out-Null
	pushd D:\APPS\edp\Program\NetParamTool\Disk1
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

if ($GLOBAL_DISABLE_FIREWALL) {
    #[VALIDATED on PS2.0], Disabling the firewall
    Write-Host ("--------------------------- Disabling the firewall ---------------------------")
    Write-Host ("Disabling domain profile...")
    netsh advfirewall set domainprofile state off
    Write-Host ("Disabling private profile...")
    netsh advfirewall set privateprofile state off
    Write-Host ("Disabling public profile...")
    netsh advfirewall set publicprofile state off
}

#Needed for sysprep
Start-Service IISADMIN
