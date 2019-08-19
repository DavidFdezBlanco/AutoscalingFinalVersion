#.\mainConfiguration.ps1 -computerName "QA-G-ASW000001" -localUserName "adminqag" -localPassword "c4YfR_W9Z%qTray3Fv7" -machineIP 10.132.4.7 -usernameDomain "testadg.esker.corp\asadmin" -passwordDomain "J&%q34LuZnEc!"
param (
	[Parameter(Mandatory=$True)] $computerName,
    [Parameter(Mandatory=$True)] $localUserName,
    [Parameter(Mandatory=$True)] $localPassword,
    [Parameter(Mandatory=$True)] $machineIP,
    [Parameter(Mandatory=$True)] $usernameDomain,
    [Parameter(Mandatory=$True)] $passwordDomain
)


#get to the current directory and change to it
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory
Write-Host "$currentDirectory"

#log-in local and session stablishment
$secstr = New-Object -TypeName System.Security.SecureString
$localPassword.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $localUserName, $secstr
$session = New-PSSession -ComputerName $machineIP -Credential $cred

# Mettre les fichiers dedans
Copy-Item "$currentDirectory\SpecializeTemplate" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\functions.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\functions.ps1' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\globalsASWeb.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\leaveDomain.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\leaveDomain.ps1' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\SpecializeProcessing.reg" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\SpecializeProcessing.reg' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\SpecializeTemplate_Part1.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\SpecializeTemplate_Part1.ps1' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\SpecializeTemplate_Part2.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\SpecializeTemplate_Part2.ps1' –ToSession $session
Copy-Item "$currentDirectory\arrangeDisks.txt" –Destination 'C:\Configure_AS_WEB\arrangeDisks.txt' –ToSession $session #maybe useless
Copy-Item "$currentDirectory\arrangingFiles.ps1" –Destination 'C:\Configure_AS_WEB\arrangingFiles.ps1' –ToSession $session #maybe useless
Copy-Item "$currentDirectory\SetASDrives.ps1" –Destination 'C:\Configure_AS_WEB\SetASDrives.ps1' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\LoadUserProfileIIS_AS.cmd" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\LoadUserProfileIIS_AS.cmd' –ToSession $session
Copy-Item "$currentDirectory\SpecializeTemplate\checkandStartServices.ps1" –Destination 'C:\Configure_AS_WEB\SpecializeTemplate\checkandStartServices.ps1' –ToSession $session

#Ordonner les disques
Write-Host "Ordering Disks"
$orderDisksPath = "C:\Configure_AS_WEB\SetASDrives.ps1"
$commandOrderPath = {param($orderDisksPath); & $orderDisksPath}
Invoke-Command -Session $session -ScriptBlock $commandOrderPath -ArgumentList $orderDisksPath

#Waiting restart
Start-Sleep -Seconds 2
$i = 0 

$parentPathCreateVM = Split-Path -parent $currentDirectory
$fileOutputRestart = "$parentPathCreateVM\Templates\WE-QA-G\test.txt"
Write-Host "$fileOutputRestart"
while($true){
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> $fileOutputRestart
    $output = Get-Content -Path $fileOutputRestart
    
    if($output -eq $null){
        Write-Host "$computerName restarted"
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

#Il faut le lancer deux fois, avat et après le reboot
Write-Host "Ordering Disks"
$session = New-PSSession -ComputerName $machineIP -Credential $cred
Invoke-Command -Session $session -ScriptBlock $commandOrderPath -ArgumentList $orderDisksPath

#Waiting restart
Start-Sleep -Seconds 2

while($true){
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> $fileOutputRestart
    $output = Get-Content -Path $fileOutputRestart
    
    if($output -eq $null){
        Write-Host "$computerName restarted"
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


#Getting into the good domain and unjoining the last one
#Getting out of an old domain, to do before destroying the machine
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$leaveDomainPath = "C:\Configure_AS_WEB\SpecializeTemplate\leaveDomain.ps1"
$globalsPath = "C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1"
$commandRunTemplateClean = {param($filepath,$globalsPath,$passwordDomain); & $filepath -GlobalsFilePath $globalsPath -passwordDomain $passwordDomain} #equivalent à .\SpecializeTemplate_Part1.ps1 .\globalsASWeb.ps1 sur la machine
Invoke-Command -Session $session -ScriptBlock $commandRunTemplateClean -ArgumentList $leaveDomainPath,$globalsPath,$passwordDomain

#Waiting restart
Start-Sleep -Seconds 2

while($true){
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> $fileOutputRestart
    $output = Get-Content -Path $fileOutputRestart
    
    if($output -eq $null){
        Write-Host "$computerName restarted"
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


#Getting into the good domain
Write-Host "Specialize template"
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$spezTemplatePath = "C:\Configure_AS_WEB\SpecializeTemplate\SpecializeTemplate_Part1.ps1"
$globalsPath = "C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1"
$commandRunTemplateClean = {param($filepath,$globalsPath,$passwordDomain); & $filepath -GlobalsFilePath $globalsPath -passwordDomain $passwordDomain} 
Invoke-Command -Session $session -ScriptBlock $commandRunTemplateClean -ArgumentList $spezTemplatePath,$globalsPath,$passwordDomain

#Waiting restart
Start-Sleep -Seconds 2

while($true){
    Enter-PSSession -ComputerName $machineIP -Credential $cred  *> $fileOutputRestart
    $output = Get-Content -Path $fileOutputRestart
    
    if($output -eq $null){
        Write-Host "$computerName restarted"
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



#Connect once as Asadmin to make the user be in the HKEY_Users registry, dont need to do anything with the session.
$secstrAsadmin = New-Object -TypeName System.Security.SecureString
$passwordDomain.ToCharArray() | ForEach-Object {$secstrAsadmin.AppendChar($_)}
$credAsadmin = new-object -typename System.Management.Automation.PSCredential -argumentlist $usernameDomain, $secstrAsadmin
$sessionAsadmin = New-PSSession -ComputerName $machineIP -Credential $credAsadmin
Start-Sleep -Seconds 30 #Waiting to create the profile on the registry

#Chef (cookbook to be debuged, does not work in qag jet, cookbook failures when acceding remotely a blob)
.\SpecializeTemplate\scriptInitBootstrapAS.ps1 -ipVMtoBootsrap $machineIP -nodeName $computerName -userNameSSH $localUserName -userPassSSH $localPassword
Start-Sleep -Seconds 30

Write-Host "Chef-client command"
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$pathChefClient = "C:\opscode\chef\bin\chef-client.bat"
$commandChefCli = {param($pathChefClient); & $pathChefClient}
Invoke-Command -Session $session -ScriptBlock $commandChefCli -ArgumentList $pathChefClient

#Launch the Specialize template 2
Write-Host "Specialize template 2 running"
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$spezTemplatePath = "C:\Configure_AS_WEB\SpecializeTemplate\SpecializeTemplate_Part2.ps1"
$globalsPath = "C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1"
$commandRunTemplateClean = {param($filepath,$globalsPath); & $filepath -GlobalsFilePath $globalsPath}
Invoke-Command -Session $session -ScriptBlock $commandRunTemplateClean -ArgumentList $spezTemplatePath,$globalsPath

#Check that all AppPools are set as load user profile = true
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$loadUserScriptPath = "C:\Configure_AS_WEB\SpecializeTemplate\LoadUserProfileIIS_AS.cmd"
$commandRunLoadUser = {param($filepath); & $filepath}
Invoke-Command -Session $session -ScriptBlock $commandRunLoadUser -ArgumentList $loadUserScriptPath

#Check services and start if stopped
$session = New-PSSession -ComputerName $machineIP -Credential $cred
$checkServicesPath = "C:\Configure_AS_WEB\SpecializeTemplate\checkandStartServices.ps1"
$globalsPath = "C:\Configure_AS_WEB\SpecializeTemplate\globalsASWeb.ps1"
$commandCheckServices = {param($filepath, $globalsPath); & $filepath $globalsPath}
Invoke-Command -Session $session -ScriptBlock $commandCheckServices -ArgumentList $checkServicesPath,$globalsPath

#Set the VM in the F5 BigIP pools.
Write-Host "Adding node to the F5 load balancer"
$fileToExecute = $currentDirectory+"SpecializeTemplate\includeNodeF5\includeToF5$computerName.txt"
Write-Host "Executing $fileToExecute"
Start-Process powershell -Credential $cred -ArgumentList "& C:\Users\adminqag\Desktop\AutoscalingFinalVersion\AutoscalingFinalVersion\bin\Debug\Resources\CREATE_VM_FROM_IMAGE\resources\Configure_AS_WEB\PLINK.exe -batch '$localUserName@10.132.1.4' -pw '$localPassword' -m '$fileToExecute'"

Exit-PSSession
<#
#Command Reboot
Write-Host "Rebooting"
$commandReboot = {shutdown /r /t 0}
Invoke-Command -Session $session -ScriptBlock $commandReboot

Start-Sleep -Seconds 40
#>
#Verify that its on
#$session = Enter-PSSession -ComputerName 10.132.4.7 -Credential $cred