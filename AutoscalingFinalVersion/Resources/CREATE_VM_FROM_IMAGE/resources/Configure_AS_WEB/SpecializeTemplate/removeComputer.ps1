param (
	[Parameter(Mandatory=$True)]
	$GlobalsFilePath
)

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE FUNCTIONS & VARIABLES
. C:\Configure_AS_WEB\SpecializeTemplate\functions.ps1
. $GlobalsFilePath

$username = "$GLOBAL_DOMAIN_ADMIN_USER"
$password = "J&%q34LuZnEc!"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 
$pc = "QA-G-ASW000001"

Write-Host ("Removing the computer from the domain")
Remove-Computer -ComputerName $pc -DomainName $GLOBAL_DOMAIN -Credential $creds –Verbose –Restart –Force
Write-Host ("")