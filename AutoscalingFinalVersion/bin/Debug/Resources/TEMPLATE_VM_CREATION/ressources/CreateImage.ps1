param ( 
    [Parameter(Mandatory=$True)]
    $ResourceGroupName,
    [Parameter(Mandatory=$True)]
    $VMName,
    [Parameter(Mandatory=$False)]
    $Location = "westeurope",
    [Parameter(Mandatory=$False)]
    $ImageName = "WE-QA-G-AS-TMPL"
)

Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

Set-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName -Generalized

$VM = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName

$Image = New-AzureRmImageConfig -Location $Location -SourceVirtualMachineId $VM.ID 

New-AzureRmImage -Image $Image -ImageName $ImageName -ResourceGroupName $ResourceGroupName

