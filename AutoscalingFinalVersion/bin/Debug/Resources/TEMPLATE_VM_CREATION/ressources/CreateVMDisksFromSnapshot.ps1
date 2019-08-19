Param
(
	[Parameter(Mandatory=$true)]$ResourceGroupName,
	[Parameter(Mandatory=$true)]$originalVMName,
	[Parameter(Mandatory=$true)]$SnapshotTag,
	$StorageType = "StandardLRS"
)

if((Get-AzureRMContext) -eq $null)
{
	Write-Host "No Azure context found, you need to login with Connect-AzureRmAccount before launching this script !"
	Exit -1
}

$VM = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $originalVMName
if($VM -eq $null)
{
	Write-Host "Could not find a vm named : $originalVMName in resource group : $ResourceGroupName"
	Exit -1
}

Write-Host "Create disks from snapshot tag $SnapshotTag"

$SnapshotNamePrefix = "$($VM.Name)-Snap-$SnapshotTag"

$OSDiskName = "$($VM.Name)-$SnapshotTag-OSDisk"
$OSDisk = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $OSDiskName -ErrorAction SilentlyContinue
if($OSDisk -eq $null)
{
	Write-Host "Creating OSDisk $OSDiskName from snapshot"
	$OSDiskSnapshot = Get-AzureRmSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName "$SnapshotNamePrefix-OSDisk"
	$OSDiskConfig = New-AzureRmDiskConfig -Location $OSDiskSnapshot.Location -SourceResourceId $OSDiskSnapshot.Id -CreateOption Copy
	$OSDisk = New-AzureRmDisk -Disk $OSDiskConfig -ResourceGroupName $ResourceGroupName -DiskName $OSDiskName 
}
else
{
	Write-Host "Found already existing OSDisk named $OSDiskName"
}

#$dataDisksSnapshots=(Get-AzureRmSnapshot -ResourceGroupName $ResourceGroupName | Where -Property Name -match "$SnapshotNamePrefix-DataDisk-*")
#foreach($dataDisksSnapshot in $dataDisksSnapshots)

foreach($dataDisk in $VM.StorageProfile.DataDisks)
{
	$dataDiskLun = $dataDisk.Lun
	$newStorageType = $dataDisk.ManagedDisk.StorageAccountType
	if (($newStorageType -eq $null) -or ($newStorageType -eq ""))
	{
		# StorageAccountType isn't available when machine is deallocated :(
		Write-Warning "Unable to determine previous storage type, fallbacking to $StorageType"
		$newStorageType = $StorageType
	}

	$newDataDiskName = "$($VM.Name)-$SnapshotTag-DataDisk-$dataDiskLun"
	$newDataDisk = $null
	$newDataDisk = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $newDataDiskName -ErrorAction SilentlyContinue
	if($newDataDisk -eq $null)
	{
		Write-Host "Creating data disk $newDataDiskName from snapshot"
		$dataDiskSnapshot = Get-AzureRmSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName "$SnapshotNamePrefix-DataDisk-$dataDiskLun"
		$dataDiskConfig = New-AzureRmDiskConfig -AccountType $newStorageType -Location $dataDiskSnapshot.Location -SourceResourceId $dataDiskSnapshot.Id -CreateOption Copy
		$newDataDisk = New-AzureRmDisk -Disk $dataDiskConfig -ResourceGroupName $ResourceGroupName -DiskName $newDataDiskName
	}
	else
	{
		Write-Host "Found already existing data disk named $newDataDiskName"
	}
}

Write-Host "End of script"

