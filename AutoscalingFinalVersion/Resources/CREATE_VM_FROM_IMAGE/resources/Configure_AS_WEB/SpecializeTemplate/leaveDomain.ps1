param (
	[Parameter(Mandatory=$True)] $GlobalsFilePath,
	[Parameter(Mandatory=$True)] $passwordDomain
)

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE FUNCTIONS & VARIABLES
. C:\Configure_AS_WEB\SpecializeTemplate\functions.ps1
. $GlobalsFilePath

$username = "$GLOBAL_DOMAIN_ADMIN_USER"
$password = $passwordDomain
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 

Write-Host ("--------------------------- Leaving previous domain ---------------------------")
Write-Host ("Removing the computer from the domain")
remove-computer -Credential $cred -PassThru -Verbose –Restart -Force
Write-Host ("Rebooting to reset domain")

 



