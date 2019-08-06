# Retrieves information from \Templates and configures the environment to make easy the machine creation
Param
(
	[Parameter(Mandatory=$true)]$ResourceGroupName,
	[Parameter(Mandatory=$true)]$location,
	[Parameter(Mandatory=$true)]$vnetName,
	[Parameter(Mandatory=$true)]$vsubnetName,
	$StorageType = "Standard_D4s_v2"
)

Write-Host "--------------- Creating environment $ResourceGroupName ---------------"

$successCode = 0
$errorCode = 1
$alreadyConfiguredCode = 2

#get to the current directory
$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

#Checks the if the folder with the templates exists
$path = "$currentDirectory\resources\Templates\AS_WEB"
$folderExists = Test-Path -Path $path
if (!$folderExists)
{
   Write-Error $folderExists
   exit $alreadyConfiguredCode
}   

#Checks the if the file variables.tf
$pathVariables = (Get-Item -Path "$path\variables.tf").FullName
$variablesExists = Test-Path -Path $pathVariables
if (!$variablesExists)
{
   Write-Error $variablesExists
   exit $alreadyConfiguredCode
}


#Checks the if the file output.tf
$pathOutput = (Get-Item -Path "$path\output.tf").FullName
$outputExists = Test-Path -Path $pathOutput
if (!$outputExists)
{
   Write-Error $outputExists
   exit $alreadyConfiguredCode
}

#Checks the if the azure provider exisits
$pathAzureProvider = (Get-Item -Path "$path\.terraform\plugins\windows_amd64\").FullName
$azureExists = Test-Path -Path $pathAzureProvider
if (!$pathAzureProvider)
{
   Write-Error $pathAzureProvider
   exit $alreadyConfiguredCode
}  

#Checks the if the Resource group repository already exists and if not it creates it
$newPath = "$currentDirectory\resources\Templates\$ResourceGroupName"
$newpathExists = Test-Path -Path $newPath
if ($newpathExists)
{  
   exit $alreadyConfiguredCode
}

$res = New-Item -Path "$newPath" -ItemType Directory
if(!$res)
{
    Write-Host "Not possible to create directory"
    exit $errorCode
}
Write-Host "Directory $res created succesfully"


$res = New-Item -Path "$newPath\.terraform" -ItemType Directory
if(!$res)
{
    Write-Host "Not possible to create directory"
    exit $errorCode
}
Write-Host "Directory $res created succesfully"


$res = New-Item -Path "$newPath\.terraform\plugins" -ItemType Directory
if(!$res)
{
    Write-Host "Not possible to create directory"
    exit $errorCode
}
Write-Host "Directory $res created succesfully"


$res = New-Item -Path "$newPath\.terraform\plugins\windows_amd64" -ItemType Directory
if(!$res)
{
    Write-Host "Not possible to create directory"
    exit $errorCode
}
Write-Host "Directory $res created succesfully"

#File configuration and content specialisation 
Write-Host "Copying the terraform variables and ouputs"
copy-item -path "$pathVariables" -destination "$newpath\variables.tf"
copy-item -path "$pathOutput" -destination "$newpath\output.tf"
copy-item -path "$pathAzureProvider\terraform-provider-azurerm_v1.31.0_x4.exe" -Destination "$newpath\.terraform\plugins\windows_amd64\terraform-provider-azurerm_v1.31.0_x4.exe"
copy-item -path "$pathAzureProvider\lock.json" -Destination "$newpath\.terraform\plugins\windows_amd64\lock.json"


Write-Host "Adapting variables to the current environment" 
(Get-Content "$newpath\variables.tf") -replace 'XXXlocationXXX', "$location" | Set-Content "$newpath\variables.tf"
(Get-Content "$newpath\variables.tf") -replace 'TEST-XX', "TEST-$ResourceGroupName" | Set-Content "$newpath\variables.tf"
(Get-Content "$newpath\variables.tf") -replace 'XXXResourceGroupXXX', "$ResourceGroupName" | Set-Content "$newpath\variables.tf"
(Get-Content "$newpath\variables.tf") -replace 'XXXvnetXXX', "$vnetName" | Set-Content "$newpath\variables.tf"
(Get-Content "$newpath\variables.tf") -replace 'XXXvsubnetXXX', "$vsubnetName" | Set-Content "$newpath\variables.tf"

#Copy terraform bin 
$pathTerraform = (Get-Item -Path "$path\terraform.exe").FullName
$terraformExists = Test-Path -Path $pathTerraform
if (!$outputExists)
{
   Write-Error $terraformExists
   exit $errorCode
}

Write-Host "Copying Terraform binary file"
copy-item -path "$pathTerraform" -destination "$newpath\terraform.exe"

Write-Host " "
exit $successCode