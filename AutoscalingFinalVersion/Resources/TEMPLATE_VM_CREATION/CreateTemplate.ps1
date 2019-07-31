#.\CreateTemplate.ps1 -ResourceGroupName "WE-QA-G" -SourceVM "WE-QA-G-AS-W01" -location "West Europe" -sprintNumber "174"
# Creates an image from which replicate the AS_WEB machines all week long 

Param
(
	[Parameter(Mandatory=$true)]$ResourceGroupName,
	[Parameter(Mandatory=$true)]$SourceVM,
	[Parameter(Mandatory=$true)]$location,
	#[Parameter(Mandatory=$true)]$vnetName,
	#[Parameter(Mandatory=$true)]$vsubnetName,
    #[Parameter(Mandatory=$true)]$index,
    [Parameter(Mandatory=$true)]$sprintNumber,
	#$StorageType = "Standard_D4s_v2",
    $tagforthesnapshot  = "ASW_AUTOSCALE_SPRINT$sprintNumber"
)

#get to the current directory
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

# Creates the snapshot of the disks of the SourceVM
.\ressources\SnapshotAzureVM.ps1 -ResourceGroupName $ResourceGroupName -VMName $SourceVM -SnapshotTag $tagforthesnapshot

#Creates the disks from the snapshots
.\ressources\CreateVMDisksFromSnapshot.ps1 -ResourceGroupName $ResourceGroupName -originalVMName $SourceVM -SnapshotTag $tagforthesnapshot

#Creates sprint Directory
New-Item -Path "ressources\$sprintNumber-AS-W" -ItemType Directory 

#Edits the template file to create an specific one for the current sprint
New-Item -Path "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json" -ItemType File 
copy-item -path "ressources\WE-G-AS-W-TEMPLATE.json" -destination "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"

(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXNAMEXXX', "WE-G-AS-W-TEMPLATE-$sprintNumber" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXVNETXXX', "WE-QA-G-VNET" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXSUBNETXXX', "AS" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXIPXXX', "10.132.4.6" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXOSDiskXXX', "$SourceVM-$tagforthesnapshot-OSDisk" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXDisk1XXX', "$SourceVM-$tagforthesnapshot-DataDisk-0" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json") -replace 'XXXDisk2XXX', "$SourceVM-$tagforthesnapshot-DataDisk-1" | Set-Content "ressources\$sprintNumber-AS-W\WE-G-AS-W-TEMPLATE-$sprintNumber.json"

#Edits the toCreate file for the current sprint
New-Item -Path "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json" -ItemType File 
copy-item -path "ressources\toCreateTemplate.json" -destination "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json"

(Get-Content "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json") -replace 'XXXNAMEXXX', "WE-G-AS-W-TEMPLATE-$sprintNumber" | Set-Content "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json"
(Get-Content "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json") -replace 'XXXRESGROUPXXX', "$ResourceGroupName" | Set-Content "ressources\$sprintNumber-AS-W\toCreate-$sprintNumber.json"

#Runs the step5 to create the VM template included on the toCreate-174 vmList
.\ressources\step5_create_VMs.ps1 -RG_NAME "WE-QA-G" -VMLIST_FILE "$currentDirectory\ressources\174-AS-W\toCreate-174.json" -TEMPLATES_DIR "$currentDirectory\ressources\" -PARAMETERS_DIR "$currentDirectory\ressources\174-AS-W\"

#Clean the VM
#prepare the folder 
New-Item -Path "ressources\TemplateClean-$sprintNumber" -ItemType Directory
copy-item -path "ressources\TemplateClean\functions.ps1" -destination "ressources\TemplateClean-$sprintNumber\functions.ps1"
copy-item -path "ressources\TemplateClean\globals.ps1" -destination "ressources\TemplateClean-$sprintNumber\globals.ps1"
copy-item -path "ressources\TemplateClean\templateClean.ps1" -destination "ressources\TemplateClean-$sprintNumber\templateClean.ps1"
copy-item -path "ressources\TemplateClean\turnOf.ps1" -destination "ressources\TemplateClean-$sprintNumber\turnOf.ps1"
copy-item -path "ressources\TemplateClean\registrySysprep.ps1" -destination "ressources\TemplateClean-$sprintNumber\registrySysprep.ps1"
(Get-Content "ressources\TemplateClean-$sprintNumber\globals.ps1") -replace 'XXXNAMEXXX', "WE-G-AS-W-TEMPLATE-$sprintNumber" | Set-Content "ressources\TemplateClean-$sprintNumber\globals.ps1"
(Get-Content "ressources\TemplateClean-$sprintNumber\globals.ps1") -replace 'XXXIPXXX', "10.132.4.6" | Set-Content "ressources\TemplateClean-$sprintNumber\globals.ps1"
(Get-Content "ressources\TemplateClean-$sprintNumber\globals.ps1") -replace 'XXXTMPXXX', "T:\apps\edp\temp" | Set-Content "ressources\TemplateClean-$sprintNumber\globals.ps1"
(Get-Content "ressources\TemplateClean-$sprintNumber\globals.ps1") -replace 'XXXDOCMANAGERXXX', "T:\apps\Esker Document Manager\Temp" | Set-Content "ressources\TemplateClean-$sprintNumber\globals.ps1"
(Get-Content "ressources\TemplateClean-$sprintNumber\templateClean.ps1") -replace 'XXXSPRITNXXX', "$sprintNumber" | Set-Content "ressources\TemplateClean-$sprintNumber\templateClean.ps1"

#Login to the template machine via WinRM (pas top sécuritée)
$username = "adminqag"
$password = "c4YfR_W9Z%qTray3Fv7"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
$session = New-PSSession -ComputerName 10.132.4.6 -Credential $cred

Copy-Item "$currentDirectory/ressources\TemplateClean-$sprintNumber" –Destination "D:\TemplateClean-$sprintNumber" –ToSession $session
Copy-Item "$currentDirectory/ressources\TemplateClean-$sprintNumber\globals.ps1" –Destination "D:\TemplateClean-$sprintNumber\globals.ps1" –ToSession $session
Copy-Item "$currentDirectory/ressources\TemplateClean-$sprintNumber\functions.ps1" –Destination "D:\TemplateClean-$sprintNumber\functions.ps1" –ToSession $session
Copy-Item "$currentDirectory/ressources\TemplateClean-$sprintNumber\templateClean.ps1" –Destination "D:\TemplateClean-$sprintNumber\templateClean.ps1" –ToSession $session
Copy-Item "$currentDirectory/ressources\TemplateClean-$sprintNumber\turnOf.ps1" –Destination "D:\TemplateClean-$sprintNumber\turnOf.ps1" –ToSession $session


$templateCleanPath = "D:\TemplateClean-$sprintNumber\templateClean.ps1"
$commandRunTemplateClean = {param($filepath); & $filepath}
Invoke-Command -Session $session -ScriptBlock $commandRunTemplateClean -ArgumentList $templateCleanPath

#Syspreps and generalises the machine
Write-Host "Generalising"
$commandChangeRegistry = {& reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\StreamProvider /v LastFullPayloadTime /t REG_DWORD /d 0}
Invoke-Command -Session $session -ScriptBlock $commandChangeRegistry

#Works at 10-7-2019
$session = New-PSSession -ComputerName 10.132.4.6 -Credential $cred
Write-Host "Rebooting script"
$turnOFPath = "D:\TemplateClean-174\turnOf.ps1"
$commandRunturnOf = {param($turnOFPath); & $turnOFPath }
Invoke-Command -Session $session -ScriptBlock $commandRunturnOf -ArgumentList $turnOFPath
Invoke-Command -Session $session -ScriptBlock $commandRunturnOf -ArgumentList $turnOFPath

$myVM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -Name "WE-G-AS-W-TEMPLATE-$sprintNumber"

while($myvm.Statuses[1].DisplayStatus -ne "VM stopped")
{
    Write-Host -NoNewline $myvm.Statuses[0].DisplayStatus ", Syspreping VM"
    Write-Host ""
    #Wait to generalising
    Start-Sleep -Seconds 30
    $myVM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -Name "WE-G-AS-W-TEMPLATE-$sprintNumber"

}

Write-Host "Creating Image"
#Create Image
.\ressources\CreateImage.ps1 -ResourceGroupName "$ResourceGroupName" -VMName "WE-G-AS-W-TEMPLATE-$sprintNumber" -ImageName "IMAGE-AS-WEB"

##Problema con sysprep

Write-Host "Removing ressources"
#Remove Context
#.\ressources\removeAll.ps1 -ResourceGroupName "$ResourceGroupName" -SourceVM "$SourceVM" -sprintNumber "$sprintNumber"
