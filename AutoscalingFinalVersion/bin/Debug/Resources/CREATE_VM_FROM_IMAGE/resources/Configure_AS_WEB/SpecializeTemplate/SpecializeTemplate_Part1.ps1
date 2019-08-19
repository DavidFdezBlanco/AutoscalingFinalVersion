param (
	[Parameter(Mandatory=$True)] $GlobalsFilePath,
	[Parameter(Mandatory=$True)] $passwordDomain
)

powershell Set-ExecutionPolicy unrestricted

#INCLUDING THE FUNCTIONS & VARIABLES
. C:\Configure_AS_WEB\SpecializeTemplate\functions.ps1
. $GlobalsFilePath

if($GLOBAL_AD_GROUP_TO_JOIN) {
    $username = "$GLOBAL_DOMAIN_ADMIN_USER"
    $password = $passwordDomain
    $secstr = New-Object -TypeName System.Security.SecureString
    $password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 

    Write-Host ("--------------------------- Joining the domain ---------------------------")
    Write-Host ("Adding the computer to the domain")
    Add-Computer -Credential $cred -DomainName $GLOBAL_DOMAIN -ComputerName $GLOBAL_COMPUTERNAME -OUPath $GLOBAL_DOMAIN_PATH –Verbose –Restart –Force
    Write-Host ("Rebooting to connect to a new domain")
    $GLOBAL_AD_GROUP_TO_JOIN = $false
}
else { Write-Host ("Ignoring domain join") -foreground "yellow" }




