param ($exeName, $ServiceName)

Write-Information "Creating Service"
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

Write-Information "Adding Recovery options"
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000

Write-Information "Adding Delayed start to the service"
sc.exe config $ServiceName start= delayed-auto

Write-Information "Starting the service"
sc.exe start $ServiceName

Write-Information "Adding Secondary recovery options"
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//
