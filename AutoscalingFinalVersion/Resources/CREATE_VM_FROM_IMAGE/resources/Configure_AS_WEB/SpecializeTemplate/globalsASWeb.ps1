#ACTION CONFIGURATION
$GLOBAL_JOIN_DOMAIN=$true
$GLOBAL_ADD_TO_ACTIVEDIRECTORY = $true
$GLOBAL_DONETPARAM=$true
$GLOBAL_UPDATE_GDRCONFIGUPDATE=$false 
$GLOBAL_DISABLE_ESKER_SERVICES=$false
$GLOBAL_START_ESKER_SERVICES=$false



#PARAMETERS
$GLOBAL_SERVICES_TO_DISABLE = @("SolrPush","MailGate","FlyDocReplTool","Faxgate","FGCONNCONT","FGPICKUP", "FGDOMINOADDIN", "INCJOBSCHED")
$GLOBAL_SERVICES_TO_START = @("ABBYY.Licensing.FineReaderEngine.Windows.10.0","Saprouter","ESKLGSNMP","IISADMIN","W3SVC")
$GLOBAL_SERVICES_TO_DELAY_START = @("SLAPDFG","FGEVENT")
$GLOBAL_COMPUTERNAME= $env:computername
#Retrieve ip
$GLOBAL_NETWORK_IP =  (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

$GLOBAL_DOMAIN="testadg.esker.corp"
$GLOBAL_DOMAIN_ADMIN_USER="$GLOBAL_DOMAIN\asadmin"
$GLOBAL_DOMAIN_PATH="OU=QAG-Computers,DC=testadg,DC=esker,DC=corp"
$GLOBAL_AD_GROUP_TO_JOIN="LDAP://OU=QAG-Computers,DC=testadg,DC=esker,DC=corp"
#FOR ASD AS : "\\172.30.3.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
#FOR ASE AS : "\\172.30.5.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
$GLOBAL_GDRCONFIG_PATH = "\\172.30.5.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
