#.\removeMachine.ps1 -ResourceGroupName "WE-QA-G" -index "000001"
param (
	[Parameter(Mandatory=$true)] $ResourceGroupName,
    [Parameter(Mandatory=$True)] $index
)

#get to the current directory and change to it
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory
$parentPath = Split-Path -parent $currentDirectory
$scriptsCreationPath = "$parentPath\CREATE_VM_FROM_IMAGE"

$computerName = "QA-G-ASW" + $index
$localUserName = "adminqag"
$localPassword = "c4YfR_W9Z%qTray3Fv7"
$usernameDomain = "testadg.esker.corp\asadmin"
$passwordDomain = "J&%q34LuZnEc!"

if($index -like "*00000*")
{
	Write-Host "Destroying machine with index $index"
}
else
{
	$index = "00000" + $index
	Write-Host "Destroying machine, index not found and adapted to $index"
}

Write-Host ""
#Retrieve the IP Needed
foreach($line in Get-Content "$scriptsCreationPath\IPConfigs\ipFix.txt") {
    if($line -like "*$index*"){ 
	$nameMachine,$machineIP,$machineStatus= $line -split ','
        Write-Host " "
        Write-Host "--------------- Destroying machine: ---------------"
        Write-Host "Name: $nameMachine, IP: $machineIP Status: $machineStatus"
        Write-Host " "
    }
}


$StartDate=(GET-DATE)
$prefixlogName = Get-Date -format "dd-MM-yyyy-HH-mm"
$logNameFile = "$prefixlogName-logs.txt" #rédiriger le output lors de l'exécution du fichier sur le service

#log-in local and session stablishment
$secstr = New-Object -TypeName System.Security.SecureString
$localPassword.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $localUserName, $secstr
$session = New-PSSession -ComputerName $machineIP -Credential $cred

#Leaving domain
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$leaveDomainPath = "C:\Configure_AS_WEB\SpecializeTemplate\leaveDomain.ps1"
$globalsPath = "C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1"
$commandRunTemplateClean = {param($filepath,$globalsPath,$passwordDomain); & $filepath -GlobalsFilePath $globalsPath -passwordDomain $passwordDomain} #equivalent à .\SpecializeTemplate_Part1.ps1 .\globalsASWeb.ps1 sur la machine
Invoke-Command -Session $session -ScriptBlock $commandRunTemplateClean -ArgumentList $leaveDomainPath,$globalsPath,$passwordDomain

#Waiting restart
Start-Sleep -Seconds 2
$i = 0 
while($true){
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> "$scriptsCreationPath\resources\Templates\WE-QA-G\test.txt"
    $output = Get-Content -Path "$scriptsCreationPath\resources\Templates\WE-QA-G\test.txt"
    
    if($output -eq $null){
        Write-Host "$computerName running"
        break
    }else{
        Write-Host "Waiting $computerName to restart"
    }

    $i = $i + 1
    if($i -eq 10){
        $i = 0
        break
    }
}

#Delete node from chef
Write-Host "Deleting node from chef"
knife node delete $computerName -yes
Write-Host "Deleting client from chef"
knife client delete $computerName -yes

#Deleting node form F5
Write-Host "Deleting node from F5"
$fileToExecute = $scriptsCreationPath+"\resources\Configure_AS_WEB\SpecializeTemplate\deleteNodeF5\deleteFromF5QA-G-ASW$index.txt"
Write-Host $fileToExecute
$pathDeleteF5 = $scriptsCreationPath+"\resources\Configure_AS_WEB\"
cd $pathDeleteF5
Start-Process powershell -Verb runAs -ArgumentList "& C:\Users\adminqag\Desktop\AutoscalingFinalVersion\AutoscalingFinalVersion\bin\Debug\Resources\CREATE_VM_FROM_IMAGE\resources\Configure_AS_WEB\PLINK.exe -batch '$localUserName@10.132.1.4' -pw '$localPassword' -m '$fileToExecute'"

#Delete with terraform
Push-Location "$scriptsCreationPath\resources\Templates\$ResourceGroupName\"
rm "$computerName.tf" -Force
Write-Host "--------------- Starting Terraform execution ---------------"
.\terraform.exe init -input=false -no-color
.\terraform.exe apply -auto-approve -no-color
Write-Host " "
Pop-Location

$user = "david.fernandez@esker.fr"
$pass = "Deefelboss1"
$secstr = New-Object -TypeName System.Security.SecureString
$pass.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $secstr
Connect-AzureRmAccount -Credential $cred

$resourcesLeftToDelete = Get-AzureRmResource | Where {$_.Name -like "*$index*"}
Foreach($resource in $resourcesLeftToDelete)
{
    if( $resource.ResourceType -like "*disk*")
    {
        Write-Host "Deleting" $resource.Name
        Remove-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $resource.Name -Force
    }
    
}

$EndDate=(GET-DATE)
$time_taken = NEW-TIMESPAN –Start $StartDate –End $EndDate
Write-Host "Machine $nameMachine deleted after $name $time_taken. " *>> $scriptsCreationPath\Logs\historyTrack\creationRecords.txt
Write-Host "        Configuration logs are saved at $scriptsCreationPath\Logs\$nameMachine\$logNameFile" *>> $scriptsCreationPath\Logs\historyTrack\creationRecords.txt
