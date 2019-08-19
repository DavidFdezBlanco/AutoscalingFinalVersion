$index ="000002"

$sourceFile = $MyInvocation.MyCommand.Source
$currentDirectory = $sourceFile.Replace($MyInvocation.MyCommand.Name,"")
cd $currentDirectory

foreach($line in Get-Content "$currentDirectory\IPConfigs\ipFix.txt") {
    if($line -like "*$index*"){ 
	$nameMachine,$ipMachine,$statusMachine = $line -split ','
        Write-Host " "
        Write-Host "--------------- Creating machine: ---------------"
        Write-Host "Name: $nameMachine, IP: $ipMachine, STATUS: $statusMachine"
        Write-Host " "
    };
};

return $ipMachine