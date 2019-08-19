#get to the directory C:\Configure_AS_WEB
cd C:\Configure_AS_WEB

#Put the System managed size on C: to be able to change the Temporary disk letter to (E:)
REG add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys 0 0" /f

#Apply the configration to arrange the disks
diskpart.exe /s .\arrangeDisks.txt

#Put the System managed size back to Temporary disk 
#REG add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "E:\pagefile.sys 0 0" /f