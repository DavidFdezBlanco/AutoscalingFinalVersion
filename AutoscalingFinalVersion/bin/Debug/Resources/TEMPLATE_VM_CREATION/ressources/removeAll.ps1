Param
(
	[Parameter(Mandatory=$true)]$ResourceGroupName,
	[Parameter(Mandatory=$true)]$SourceVM,
	#[Parameter(Mandatory=$true)]$location,
	#[Parameter(Mandatory=$true)]$vnetName,
	#[Parameter(Mandatory=$true)]$vsubnetName,
    #[Parameter(Mandatory=$true)]$index,
    [Parameter(Mandatory=$true)]$sprintNumber,
	#$StorageType = "Standard_D4s_v2",
    $tagforthesnapshot  = "ASW_AUTOSCALE_SPRINT$sprintNumber"
)

Remove-AzureRmVM -Name "WE-G-AS-W-TEMPLATE-$sprintNumber" -ResourceGroupName "$ResourceGroupName" -Force
Remove-AzureRmNetworkInterface -Name "WE-G-AS-W-TEMPLATE-$sprintNumber-NIC" -ResourceGroup "$ResourceGroupName" -Force

Remove-AzureRmDisk -ResourceGroupName "$ResourceGroupName" -DiskName "$SourceVM-$tagforthesnapshot-OSDisk" -Force
Remove-AzureRmDisk -ResourceGroupName "$ResourceGroupName" -DiskName "$SourceVM-$tagforthesnapshot-DataDisk-1" -Force 
Remove-AzureRmDisk -ResourceGroupName "$ResourceGroupName" -DiskName "$SourceVM-$tagforthesnapshot-DataDisk-0" -Force
