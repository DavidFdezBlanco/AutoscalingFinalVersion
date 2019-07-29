#ACTION CONFIGURATION
$GLOBAL_CLEAR_WINDOWS_EVENTLOG=$true
$GLOBAL_DONETPARAM=$true
$GLOBAL_STOP_ESKER_SERVICES=$true
$GLOBAL_START_ESKER_SERVICES=$true
$GLOBAL_PURGE_EDP_FILES=$true
$GLOBAL_DISABLE_FIREWALL=$false

#PARAMETERS
$GLOBAL_SERVICES_TO_STOP = @( "FGPICKUP","FGEVENT","FGCONNCONT","Faxgate","FlyDocReplTool","MailGate","FGSFTS","W3SVC","IISADMIN","ESKLGSNMP","SolrPush","Saprouter","ABBYY.Licensing.FineReaderEngine.Windows.10.0","SLAPDFG")
$GLOBAL_SERVICES_TO_START = @("SLAPDFG","ABBYY.Licensing.FineReaderEngine.Windows.10.0","Saprouter","SolrPush","ESKLGSNMP","IISADMIN","W3SVC","FGSFTS","MailGate","FlyDocReplTool","Faxgate","FGCONNCONT","FGEVENT","FGPICKUP")
$GLOBAL_COMPUTERNAME="WE-G-AS-W-TEMPLATE-174"
$GLOBAL_NETWORK_INTERFACENAME="Microsoft Hyper-V Network Adapter"
$GLOBAL_NETWORK_IP="10.132.4.6"
$GLOBAL_TempFolder="T:\apps\edp\temp"
$GLOBAL_DocMgrTemp="T:\apps\Esker Document Manager\Temp"

#OTHERS
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Choose Y to continue"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Choose N to ignore this step."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
