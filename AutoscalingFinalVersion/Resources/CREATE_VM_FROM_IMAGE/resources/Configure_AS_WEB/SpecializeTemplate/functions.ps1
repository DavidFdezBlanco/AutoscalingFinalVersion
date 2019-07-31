function Pause ($Message="Press any key to continue..."){
	Write-Host -NoNewLine $Message
	Start-Sleep 2 #pause two seconds
	Write-Host ""
}
