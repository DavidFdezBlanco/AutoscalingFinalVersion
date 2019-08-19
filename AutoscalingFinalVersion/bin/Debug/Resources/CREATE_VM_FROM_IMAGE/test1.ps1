$StartDate=(GET-DATE)
$computerName = "QA-G-ASW000001"
$ResourceGroupName = "WE-QA-G"

$username = "adminqag"
$password = "c4YfR_W9Z%qTray3Fv7"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 
$session = New-PSSession -ComputerName 10.132.4.7 -Credential $cred

Write-Host "Rebooting"
$commandReboot = {shutdown /r /f /t 0}
Invoke-Command -Session $session -ScriptBlock $commandReboot

Start-Sleep -Seconds 2

while($true){
Enter-PSSession -ComputerName 10.132.4.7 -Credential $cred  *> C:\Users\adminqag\Desktop\Autoscaling\CREATE_VM_FROM_IMAGE\resources\Templates\WE-QA-G\test.txt
$output = Get-Content -Path C:\Users\adminqag\Desktop\Autoscaling\CREATE_VM_FROM_IMAGE\resources\Templates\WE-QA-G\test.txt
    
    if($output -eq $null){
        Write-Host "Works"
        break
    }else{
        Write-Host "Doesn't Work"
    }
}

$EndDate=(GET-DATE)
$time_taken = NEW-TIMESPAN –Start $StartDate –End $EndDate
Write-Host $time_taken


<#
while($true){


    if($joining -ne $null){
        Write-host "dope"
    }else{
        Write-host "nope"
    }
}
#>
<#
while($true)
{
    if(Enter-PSSession -ComputerName 10.132.4.7 -Credential $cred){
        Write-host "exit $?"
    }
    else
    {
        Write-host "exit $?"
    }
}#>