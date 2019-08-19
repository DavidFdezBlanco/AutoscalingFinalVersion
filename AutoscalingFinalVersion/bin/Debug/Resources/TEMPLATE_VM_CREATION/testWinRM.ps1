$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

#Login to the template machine via WinRM (pas top sécuritée)
$username = "adminqag"
$password = "c4YfR_W9Z%qTray3Fv7"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
$session = Enter-PSSession -ComputerName 10.132.4.6 -Credential $cred



Write-Host "Reboot"
$turnOFPath = "D:\TemplateClean-174\turnOf.ps1"
$commandRunturnOf = {param($turnOFPath); & $turnOFPath }
Invoke-Command -Session $session -ScriptBlock $commandRunturnOf -ArgumentList $turnOFPath