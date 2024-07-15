param ($exeName, $ServiceName)

Write-Host "Creating Service"
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

Write-Host "Adding Recovery options"
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000

Write-Host "Adding Delayed start to the service"
sc.exe config $ServiceName start= delayed-auto

Write-Host "Starting the service"
sc.exe start $ServiceName

Write-Host "Adding Secondary recovery options"
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//
