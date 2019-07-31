#.\removeMachine.ps1 -ResourceGroupName "WE-QA-G" -index "000001" -computerName "QA-G-ASW000001" -localUserName "adminqag" -localPassword "c4YfR_W9Z%qTray3Fv7" -machineIP 10.132.4.7 -usernameDomain "testadg.esker.corp\asadmin" -passwordDomain "J&%q34LuZnEc!"

param (
	[Parameter(Mandatory=$true)] $ResourceGroupName,
	[Parameter(Mandatory=$True)] $computerName,
    [Parameter(Mandatory=$True)] $localUserName,
    [Parameter(Mandatory=$True)] $localPassword,
    [Parameter(Mandatory=$True)] $machineIP,
    [Parameter(Mandatory=$True)] $usernameDomain,
    [Parameter(Mandatory=$True)] $passwordDomain,
    [Parameter(Mandatory=$True)] $index
)

$StartDate=(GET-DATE)
$logNameFile = "$prefixlogName-delete-logs.txt" #rédiriger le output lors de l'exécution du fichier sur le service

#get to the current directory and change to it
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

$parentPath = Split-Path -parent $currentDirectory
$scriptsCreationPath = "$parentPath\CREATE_VM_FROM_IMAGE"

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
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> C:\Users\adminqag\Desktop\Autoscaling\CREATE_VM_FROM_IMAGE\resources\Templates\WE-QA-G\test.txt
    $output = Get-Content -Path C:\Users\adminqag\Desktop\Autoscaling\CREATE_VM_FROM_IMAGE\resources\Templates\WE-QA-G\test.txt
    
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
knife node delete "$computerName" -yes

#Sortir du F5

#Delete with terraform
Push-Location "$scriptsCreationPath\resources\Templates\$ResourceGroupName\"
rm "$computerName.tf" -Force
Write-Host "--------------- Starting Terraform execution ---------------"
.\terraform.exe init -input=false -no-color
.\terraform.exe apply -auto-approve -no-color
Write-Host " "
Pop-Location
#>
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
Write-Host "Machine $nameMachine deleted after $name $time_taken. " *>> $currentDirectory\Logs\historyTrack\creationRecords.txt
Write-Host "        Configuration logs are saved at $currentDirectory\Logs\$nameMachine\$logNameFile" *>> $currentDirectory\Logs\historyTrack\creationRecords.txt
