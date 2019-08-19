 #.\scriptInitBootstrapAS.ps1 -ipVMtoBootsrap 10.132.4.7 -nodeName "QA-G-ASW000001" -userNameSSH "adminqag" -userPassSSH "c4YfR_W9Z%qTray3Fv7"
 param (
    [IPAddress]$ipVMtoBootsrap, 
    [string]$nodeName,
    [string]$userNameSSH,
    [string]$userPassSSH,
    [string]$runList = "recipe[eod_role_as_web]" ,
    [string]$environment = "azure_qa_g",
    [string]$bootstrapVaultJson = '{"accesskeys" : ["eskerqasharedartifacts01", "eskerweqagbackup01", "eskerweqagedpdata01", "eskerweqagtempdir01"], "passwords": ["asadmin", "adminqag"]}',
    [switch]$help = $false
 )

 $myJsonObject = $bootstrapVaultJson
 $myOutput = $myJsonObject | ConvertTo-Json

echo " " "######################################" "####        Initialising          ####" "######################################" " "
if (!$help) {
  If (!$ipVMtoBootsrap -or !$userNameSSH -or !$nodeName -or !$userPassSSH){
    $help = $true
    echo "Please indicate the following parameters"
    &  "echo "Please indicate the following parameters"" 
  }
  Else {
    write-host -NoNewline "VM IP to configure:" $ipVMtoBootsrap.IPAddressToString 
    echo " "
    write-host -NoNewline "Node Name:" $nodeName
    echo " "
    write-host -NoNewline "----    SSH Credentials:    ----" 
    echo " "
    write-host -NoNewline "    Name: " $userNameSSH 
    echo " "
    Write-Host -NoNewline "    Password:" $userPassSSH
    echo " "
    echo "--------------------------------"
    
    echo " " "######################################" "#####        Launching           #####" "######################################" " "
    
    knife node delete $nodeName -yes
    knife client delete $nodeName -yes

    knife bootstrap windows winrm -yes $ipVMtoBootsrap.IPAddressToString --node-name $nodeName --winrm-user $userNameSSH --winrm-password $userPassSSH --run-list $runList --environment $environment --bootstrap-vault-json $myOutput
    #il y a des problèmes avec les cookbooks sur la qag, voir avec julien quand il retourne
    
    echo "Updating databag private key for the $nodeName client"
    Write-Host "eskerweqaglogs ... "
    knife vault update "accesskeys" "eskerweqaglogs" -C "$nodeName"
    
    Write-Host "eskerweqagbackup01 ..."
    knife vault update "accesskeys" "eskerweqagbackup01" -C "$nodeName"
    
    Write-Host "eskerweqagtempdir01 ..."
    knife vault update "accesskeys" "eskerweqagtempdir01" -C "$nodeName"
    
    Write-Host "eskerqasharedartifacts01 ..."
    knife vault update "accesskeys" "eskerqasharedartifacts01" -C "$nodeName"
    
    Write-Host "eskerweqagedpdata01 ..."
    knife vault update "accesskeys" "eskerweqagedpdata01" -C "$nodeName"

    echo "Updating the password keys for the $nodeName client"
    
    Write-Host "adminqag ..."
    knife vault update "passwords" "adminqag" -C "$nodeName"
    
    Write-Host "asadmin ..."
    knife vault update "passwords" "adminqag" -C "$nodeName"  

    }
}

if ($help) {
  echo "[MANDATORY Flags]:"
  echo "        [-ipVMtoBootsrap] => Ip from the machine you want to bootrap"
  echo "        [-nodeName] => Name of the machine to bootstrap administrator"
  echo "        [-userNameSSH] => Name of the machine administrator that you want to Bootstrap"
  echo "        [-userPassSSH] => Password of the machine administrator that you want to Bootstrap"
  echo ""
  echo "[OTHER FLAGS]"
  echo "        [-runList] => recipe[eod_we_qag_es_test::data] by default. Specify the recipy to run"
  echo "        [-environment] => Password of the machine administrator that you want to Bootstrap"
}