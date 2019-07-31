param (
	[Parameter(Mandatory=$True)] $GlobalsFilePath
)

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE VARIABLES
. $GlobalsFilePath


Write-Host "****************** Checking automatic start services ******************"

foreach ($element in $GLOBAL_SERVICES_TO_START)
{	
	$serviceName = Get-Service | Where-Object {$_.Name -eq "$element"} | select Name
	if($serviceName)
	{	
		Write-Host ""
		Write-Host "----------- Service $serviceName -----------" 
		#Display service settings to debug
		Get-Service | Where-Object {$_.Name -eq "$element"} | select *

		if( (Get-Service | Where-Object {$_.Name -eq "$element"} | select Status ) -match "Running")
		{	
			Write-Host "Service $serviceName is already Running"
		}
		elseif( (Get-Service | Where-Object {$_.Name -eq "$element"} | select Status ) -match "Stopped")
		{	
			Write-Host "Service $serviceName is Stopped, Starting service ... "
			start-service $serviceName
			Write-Host "Service $serviceName is started."
		}
		if((Get-Service | Where-Object {$_.Name -eq "$element"} | select StartType) -match "Automatic")
		{
			Write-Host "Service $serviceName is in Automatic startup mode"
		}
		else
		{
			Write-Host "Service $serviceName is not automatic. Setting automatic startup mode ... "
			Set-Service -Name $element -StartupType "Automatic"
			Write-Host "Service $serviceName set in Automatic startup mode"
		}
	}
}

Write-Host "****************** Checking delayed start services ******************"

foreach ($element in $GLOBAL_SERVICES_TO_DELAY_START)
{	
	$serviceName = Get-Service | Where-Object {$_.Name -eq "$element"} | select Name
	if($serviceName)
	{	
		Write-Host ""
		Write-Host "----------- Service $serviceName -----------" 
		#Display service settings to debug
		Get-Service | Where-Object {$_.Name -eq "$element"} | select *

		if( (Get-Service | Where-Object {$_.Name -eq "$element"} | select Status ) -match "Running")
		{	
			Write-Host "Service $serviceName is already Running"
		}
		elseif( (Get-Service | Where-Object {$_.Name -eq "$element"} | select Status ) -match "Stopped")
		{	
			Write-Host "Service $serviceName is Stopped, Starting service ... "
			start-service $serviceName
			Write-Host "Service $serviceName is started."
		}
		if((Get-Service | Where-Object {$_.Name -eq "$element"} | select StartType) -match "AutomaticDelayedStart")
		{
			Write-Host "Service $serviceName is in Automatic Delayed Start startup mode"
		}
		else
		{
			Write-Host "Service $serviceName is not automatic. Setting automatic delayed start startup mode ... "
			sc.exe config $serviceName start= delayed-auto
			Write-Host "Service $serviceName set in Automatic Delayed Start sstartup mode"
		}
	}
}





