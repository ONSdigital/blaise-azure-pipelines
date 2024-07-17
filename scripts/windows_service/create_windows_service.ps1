param ($exeName, $ServiceName)

Write-Host "Creating Windows service $ServiceName"
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

Write-Host "Adding recovery options to Windows service $ServiceName"
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000

Write-Host "Adding delayed start to Windows service $ServiceName"
sc.exe config $ServiceName start= delayed-auto

Write-Host "Starting Windows service $ServiceName"
sc.exe start $ServiceName

Write-Host "Adding secondary recovery options to Windows service $ServiceName"
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//
