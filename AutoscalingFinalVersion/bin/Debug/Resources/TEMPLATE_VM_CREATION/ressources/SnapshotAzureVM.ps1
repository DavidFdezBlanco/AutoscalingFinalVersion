Param
(
	[Parameter(Mandatory=$true)] [string] $ResourceGroupName,
	[Parameter(Mandatory=$true)] [string] $VMName,
	[Parameter(Mandatory=$true)] [string] $SnapshotTag,
	[Parameter(Mandatory=$false)] [switch] $ForceOverwrite
)

if((Get-AzureRMContext) -eq $null)
{
	Write-Host "No Azure context found, you need to login with Connect-AzureRmAccount before launching this script !"
	Exit -1
}

$VM = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName
if($VM -eq $null)
{
	Write-Host "Could not find a vm named : $VMName in resource group : $ResourceGroupName"
	Exit -1
}

function ShouldOverwriteSnap()
{
	$Title = "Overwrite snapshot?"
	$Message = "Yes to overwrite existing snapshot ; No to keep the old snapshot:"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', "Overwrite snapshot. Will in fact remove the previous snapshot to create a new one with a correct creation time (otherwise date isn't updated)."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', "Does not overwrite snapshot. Will do nothing. Old snapshot is kept intact."
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no);
	$answer = $host.ui.PromptForChoice($Title, $Message, $choices, 0)
	return $answer -eq 0
}

function CheckSnapExistence($ResourceGroupName, $SnapName, $ForceOverwrite)
{
	$createOrUpdateSnap = $true
	$snap = Get-AzureRmSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapName -ErrorAction SilentlyContinue
	if ($snap -ne $null)
	{
		Write-Warning "There is already an existing snapshot named $SnapName"
		Write-Warning "Time created: $($snap.TimeCreated)"
		if ($ForceOverwrite -or $(ShouldOverwriteSnap))
		{
			Write-Host "Removing previous snapshot..."
			Remove-AzureRmSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapName -Force
			Write-Host "Removed"
			$createOrUpdateSnap = $true
		}
		else
		{
			$createOrUpdateSnap = $false
		}
	}
	return $createOrUpdateSnap
}


$SnapshotNamePrefix = "$($VM.Name)-Snap-$SnapshotTag"
Write-Host "Snapshotting $VMName disks with prefix $SnapshotNamePrefix"

Write-Host "OSDisk:"
$OSDiskSnapshotName = "$SnapshotNamePrefix-OSDisk"
$createOrUpdateSnap = CheckSnapExistence $ResourceGroupName $OSDiskSnapshotName $ForceOverwrite
if ($createOrUpdateSnap)
{
	$snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $VM.StorageProfile.OsDisk.ManagedDisk.Id -Location $VM.Location -CreateOption Copy
	Write-Host "Create OSDisk ($($VM.StorageProfile.OsDisk.Name)) snapshot: $OSDiskSnapshotName"
	New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName $OSDiskSnapshotName -ResourceGroupName $ResourceGroupName
}

Write-Host "Data Disks:"
$VM.StorageProfile.DataDisks | ForEach-Object {
	$diskId = $_.Lun
	$DataDiskSnapshotName = "$SnapshotNamePrefix-DataDisk-$diskId"
	$createOrUpdateSnap = CheckSnapExistence $ResourceGroupName $DataDiskSnapshotName $ForceOverwrite
	if ($createOrUpdateSnap)
	{
		$snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $_.ManagedDisk.Id -Location $VM.Location -CreateOption Copy
		Write-Host "Create data disk ($($_.Name)) snapshot: $DataDiskSnapshotName"
		New-AzureRmSnapshot -Snapshot $snapshotConfig -SnapshotName $DataDiskSnapshotName -ResourceGroupName $ResourceGroupName
	}
}

Write-Host "End of script"