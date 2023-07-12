param ($exeName, $ServiceName)

Write-Output "Creating Service"
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

Write-Output "Adding Recovery options"
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000

Write-Output "Adding Delayed start to the service"
sc.exe config $ServiceName start= delayed-auto

Write-Output "Starting the service"
sc.exe start $ServiceName

Write-Output "Adding Secondary recovery options"
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//
