#ACTION CONFIGURATION
$GLOBAL_JOIN_DOMAIN=$true
$GLOBAL_DONETPARAM=$true
$GLOBAL_UPDATE_GDRCONFIGUPDATE=$false 
$GLOBAL_DISABLE_ESKER_SERVICES=$true
$GLOBAL_START_ESKER_SERVICES=$true


#PARAMETERS
$GLOBAL_SERVICES_TO_DISABLE = @("MailGate","Faxgate","FGCONNCONT","FGPICKUP", "FGDOMINOADDIN", "INCJOBSCHED")
$GLOBAL_SERVICES_TO_START = @("ESKLGSNMP","IISADMIN","W3SVC")
$GLOBAL_SERVICES_TO_DELAY_START = @("SLAPDFG","FGEVENT")
$GLOBAL_COMPUTERNAME="SG-ROUTE02"
$GLOBAL_NETWORK_IP="10.30.1.82"
$GLOBAL_DOMAIN="housing.net"
$GLOBAL_DOMAIN_ADMIN_USER="housing\asservice"
$GLOBAL_DOMAIN_PATH="OU=Application Servers,OU=Processing Computers,OU=EOD Computers,DC=housing,DC=net"
$GLOBAL_AD_GROUP_TO_JOIN="LDAP://CN=G Applications Servers,OU=Application Servers,OU=Processing Computers,OU=EOD Computers,DC=housing,DC=net"
#FOR ASD AS : "\\172.30.3.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
#FOR ASE AS : "\\172.30.5.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
$GLOBAL_GDRCONFIG_PATH = "\\172.30.5.185\d$\apps\edp\Program\GDRTools\GDRConfigUpdate.exe.Platform.config"
