Write-Host "Changing Registry"
& reg add HKEY_LOCAL_MACHINE\System\Setup\Status\SysprepStatus /v GeneralizationState /t REG_DWORD /d 7 /f
& reg add HKEY_LOCAL_MACHINE\System\Setup\Status\SysprepStatus /v CleanupState /t REG_DWORD /d 2 /f
& reg add HKEY_LOCAL_MACHINE\Software\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform /v SkipRearm /t REG_DWORD /d 1 /f

Write-Host  "Generalising"
cd C:\Windows\System32\Sysprep
Get-ChildItem -path "C:\Windows\System32\Sysprep\" -Directory -Filter "Panther" | Remove-Item -Recurse -Confirm:$false -Force
.\sysprep.exe /generalize /shutdown /oobe /mode:vm
Write-Host  "Done"