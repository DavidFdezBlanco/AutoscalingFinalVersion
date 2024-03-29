# Retrieves information from \Ressource-Groups\Templates and configures the environment and the new machine
Param
(
	[Parameter(Mandatory=$true)]$ResourceGroupName,
	[Parameter(Mandatory=$true)]$location,
	[Parameter(Mandatory=$true)]$vnetName,
	[Parameter(Mandatory=$true)]$vsubnetName,
    [Parameter(Mandatory=$true)]$index,
    [Parameter(Mandatory=$true)]$sprintNumber,
    [Parameter(Mandatory=$true)]$adminqagUser,
    [Parameter(Mandatory=$true)]$adminqagPass,
    [Parameter(Mandatory=$true)]$asadminUser,
    [Parameter(Mandatory=$true)]$asadminPass,
	$StorageType = "Standard_D4s_v2",
    $SourceVM = "WE-QA-G-AS-W01"
)

Write-Host "Adminqag User: $adminqagUser et Pass: $adminqagPass"
Write-Host "Asadmin User: $asadminUser et Pass: $asadminPass"

if($index -like "*00000*")
{
	Write-Host "Creating machine with index $index"
}
else
{
	$index = "00000" + $index
	Write-Host "Creating machine, index not found and adapted to $index"
}


$StartDate=(GET-DATE)
$prefixlogName = Get-Date -format "dd-MM-yyyy-HH-mm"
$logNameFile = "$prefixlogName-logs.txt" #r�diriger le output lors de l'ex�cution du fichier sur le service

#get to the current directory
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

#Retrieve the IP Needed
foreach($line in Get-Content "$currentDirectory\IPConfigs\ipFix.txt") {
    if($line -like "*$index*"){ 
	$nameMachine,$ipMachine,$machineStatus= $line -split ','
        Write-Host " "
        Write-Host "--------------- Creating machine: ---------------"
        Write-Host "Name: $nameMachine, IP: $ipMachine, Status: $machineStatus"
        Write-Host " "
    }
}


$configurationResult = .\ConfigureEnvironment.ps1 -location $location -ResourceGroupName $ResourceGroupName -vnetName $vnetName -vsubnetName $vsubnetName
if($LastExitCode -eq 1)
{
    Write-Host "Error creating environment"
    Write-Host " "
    exit
}
elseif($LastExitCode -eq 2)
{
    Write-Host "Environment $ResourceGroupName already configured"
    Write-Host " "
}

#Checks the if the file ASWEBVMCreationFromImageTemplate.tf exists
Write-Host "--------------- Adapting the machine terraform template QA-G-ASW$index.tf ---------------"
$pathMainTemplate = "$currentDirectory\resources\Templates\AS_WEB\ASWEBVMCreationFromImageTemplate.tf"
$mainExists = Test-Path -Path $pathMainTemplate
if (!$mainExists)
{
   Write-Error $mainExists
   exit
}

$newPath = "$currentDirectory\resources\Templates\$ResourceGroupName"
Write-Host "Copying file $pathMainTemplate into $newpath\QA-G-ASW$index.tf"
copy-item -path "$pathMainTemplate" -destination "$newpath\QA-G-ASW$index.tf"

#Adapts the template
Write-Host "Setting index to $index"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'XXXXXX', "$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
Write-Host "Setting Sprint number to $sprintNumber"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'ASW_AUTOSCALE_SPRINTXXX', "ASW_AUTOSCALE_SPRINT$sprintNumber" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'index', "index$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'vm_hostname', "vm_hostname$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'tagforthesnapshot', "tagforthesnapshot$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'os_disk_XXXXXX', "os_disk_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'data_disk_1_XXXXXX', "data_disk_1_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'data_disk_2_XXXXXX', "data_disk_2_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'network_interface_XXXXXX', "network_interface_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'ES_DATA_VM_XXXXXX', "ES_DATA_VM_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'BGInfo_XXXXXX', "BGInfo_$index" | Set-Content "$newpath\QA-G-ASW$index.tf"
Write-Host "Setting IP to $ipMachine"
(Get-Content "$newpath\QA-G-ASW$index.tf") -replace 'XXXIPXXX', "$ipMachine" | Set-Content "$newpath\QA-G-ASW$index.tf"
Write-Host " "

Push-Location $newPath
Write-Host "--------------- Starting Terraform execution ---------------"
.\terraform.exe init -input=false -no-color
.\terraform.exe apply -auto-approve -no-color
Write-Host " "
Pop-Location


#To change how to retrieve the ip from the terraform tfstate with regex parsing
cd $currentDirectory
.\resources\Configure_AS_WEB\mainConfiguration.ps1 -computerName "$nameMachine" -localUserName $adminqagUser -localPassword "$adminqagPass" -machineIP $ipMachine -usernameDomain "testadg.esker.corp\$asadminUser" -passwordDomain "$asadminPass" 
$EndDate=(GET-DATE)
$time_taken = NEW-TIMESPAN -Start $StartDate -End $EndDate
Write-Host "Machine $nameMachine created after $name $time_taken. " *>> $currentDirectory\Logs\historyTrack\creationRecords.txt
Write-Host "        Configuration logs are saved at $currentDirectory\Logs\$nameMachine\$logNameFile" *>> $currentDirectory\Logs\historyTrack\creationRecords.txt

#.\createMachine.ps1  -location "West Europe" -ResourceGroupName "WE-QA-G" -vnetName "WE-QA-G-VNET" -vsubnetName "AS" -index "000001" -sprintNumber "174" -adminqagUser "adminqag" -adminqagPass "c4YfR_W9Z%qTray3Fv7" -asadminUser "asadmin" -asadminPass "J&%q34LuZnEc!"
