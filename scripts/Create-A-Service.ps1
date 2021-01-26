param ($exeName, $ServiceName)

Write-Host "Creating Service"
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

Write-Host "Adding Recovery options"
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000
sc.exe failure $ServiceName command= "\"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe\"Powershell -c C:\dev\stackdriver\logsServiceFailure.ps1 -ServiceName $ServiceName"

Write-Host "Adding Delayed start to the service"
sc.exe config $ServiceName start= delayed-auto

Write-Host "Starting the service"
sc.exe start $ServiceName

Write-Host "Adding Secondary recovery options"
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//

Write-Host "Disable StartService ScheduledTask"
Get-ScheduledTask -TaskName  "StartService" | Enable-ScheduledTask
