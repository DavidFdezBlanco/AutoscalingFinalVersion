#DATE    :: 03/10/2017
#AUTHOR  :: TM
#GOAL    :: Create all needed VMs
#DOC     :: None
#MODE    :: Template (Powershell/Classic/Template)
#---------------------------------------------------------------------------------------------------

Param(
    [Parameter(Mandatory=$True)]   [string] $RG_NAME,

    [Parameter(Mandatory=$False)]  [string] $TEMPLATES_DIR   = [System.IO.Path]::Combine($PSScriptRoot,'Templates\VirtualMachines\'),
    [Parameter(Mandatory=$False)]  [string] $PARAMETERS_DIR  = [System.IO.Path]::Combine($PSScriptRoot,'..\..\Configuration\TowerG\VMParameters\'),
    [Parameter(Mandatory=$False)]  [string] $VMLIST_FILE     = [System.IO.Path]::Combine($PARAMETERS_DIR ,'ProdWE-G.json'),
    [Parameter(Mandatory=$False)]  [string] $ChefPublicCertificateFile = "",
    [Parameter(Mandatory=$False)]  [string] $ChefPrivateUserKeyFile = ""

)


Write-Host "-------------------------------------------------------------"
Write-Host "                     PRE-CHECKS                              "
Write-Host "-------------------------------------------------------------"

$vmlist_JSON = Get-Content $VMLIST_FILE -Raw | ConvertFrom-Json
$atLeastOneVMusesChef = $false
foreach($VM in $vmlist_JSON.vmList) {

    Write-Host "# "$VM.vmName

    If (Test-Path ($TEMPLATES_DIR+$VM.templateName)) { 
        Write-Host "  -> Template found  : "$VM.templateName
    } else {
        Write-Host "  -> Template not found  : "$VM.templateName
        Write-Error "Aborting. Template and parameters must exist. Check path , name and modify your vmList file."
        Exit
    }

    #If parameterName is not defined, we use vmName by default
    if ($VM.parameterName -eq $null) {Add-Member -InputObject $VM -MemberType NoteProperty -Name parameterName -Value ($VM.vmName+".json");}
    
    If (Test-Path ($PARAMETERS_DIR+$VM.parameterName)) { 
        Write-Host "  -> Parameter found : "$VM.parameterName
    } else {
        Write-Host "  -> Parameter not found  : "$VM.parameterName
        Write-Error "Aborting. Template and parameters must exist. Check path , name and modify your vmList file."
        Exit
    }

    If ($VM.installChef -eq "True") {
         Write-Host "  -> Chef  : Yes"
         $atLeastOneVMusesChef = $true
    }
}

Write-Host "-------------------------------------------------------------"
Write-Host "Number of VMs to create/update : "($vmlist_JSON.vmList).Count
Write-Host "All checks passed."

$rep = Read-Host "Are you sure you want to continue (y/n)?`r`n"
If ($rep -ne "y"){Exit;}


Write-Host "-------------------------------------------------------------"
Write-Host "                Securized parameters                         "
Write-Host "-------------------------------------------------------------"

Write-Host "We 'll ask you few parameters that will be used for all following VMs`n"
$AdminPassword = "eskpass06Esk$"

If ($atLeastOneVMusesChef -eq $true) {
    Write-Host "-----------------"
    Write-Host "Chef settings"
    
    if ($ChefPublicCertificateFile -eq ""){ # not given via Parameter
        $ChefPublicCertificateFile = Read-Host "Please enter path to Public Chef server certificate (.crt). You can find this file under LY-PASS\Azure\Third Party\Chef Automation admin account "
    }
    $ChefPublicCertificate = Get-Content $ChefPublicCertificateFile -Raw -ErrorAction Stop
    if (!$ChefPublicCertificate.StartsWith("-----BEGIN CERTIFICATE-----")) {
        Write-Error "Aborting. Your path to public PEM is wrong. File is not starting by '-----BEGIN CERTIFICATE-----'"
        Exit 
    }

    if ($ChefPrivateUserKeyFile -eq ""){ # not given via Parameter
        $ChefPrivateUserKeyFile = Read-Host "Please enter path to Private User Key file (.pem) for user you define as 'chef_validation_client_name' (default=automate_admin) . You can find this file under LY-PASS\Azure\Third Party\Chef Automation admin account"
    }
    $ChefPrivateUserKey = Get-Content $ChefPrivateUserKeyFile -Raw -ErrorAction Stop
    if (!$ChefPrivateUserKey.StartsWith("-----BEGIN RSA PRIVATE KEY-----")) {
        Write-Error "Aborting. Your path to Private User Key file for user you define as 'chef_validation_client_name' is wrong. File is not starting by '-----BEGIN RSA PRIVATE KEY-----'"
        Exit 
    }


}


Write-Host "-------------------------------------------------------------"
Write-Host "                Starting creation/update                     "
Write-Host "-------------------------------------------------------------"


foreach($VM in $vmlist_JSON.vmList) {
    Write-Host "Starting "$VM.vmName
    If ($VM.installChef -eq "True") {
        $Dep = New-AzureRmResourceGroupDeployment -Verbose `
            -Name "create_VMs" `
            -ResourceGroupName $RG_NAME `
            -TemplateFile ($TEMPLATES_DIR+$VM.templateName) `
            -TemplateParameterFile ($PARAMETERS_DIR+$VM.parameterName) `
            -chef_validation_key $ChefPrivateUserKey `
            -chef_server_crt $ChefPublicCertificate
    } else {
        $Dep = New-AzureRmResourceGroupDeployment -Verbose `
            -Name "create_VMs" `
            -ResourceGroupName $RG_NAME `
            -TemplateFile ($TEMPLATES_DIR+$VM.templateName) `
            -TemplateParameterFile ($PARAMETERS_DIR+$VM.parameterName) `
    }
    $Dep
}




Write-Host "----------------------------------------------------------"
Write-Host "Finished                                                  "
Write-Host "----------------------------------------------------------"