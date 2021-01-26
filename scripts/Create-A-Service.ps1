param ($exeName, $BuildName)

Write-Host "Creating Service"
sc.exe create $BuildName binpath=C:\BlaiseServices\$BuildName\$exeName.exe

Write-Host "Adding Recovery options"
sc.exe failure $BuildName reset= 1 actions= restart/60000/run/1000
sc.exe failure $BuildName command= "\"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe\"Powershell -c C:\dev\stackdriver\logsServiceFailure.ps1 -ServiceName $BuildName"

Write-Host "Adding Delayed start to the service"
sc.exe config $BuildName start= delayed-auto

Write-Host "Starting the service"
sc.exe start $BuildName

Write-Host "Adding Secondary recovery options"
sc.exe failure $BuildName reset= 7200 actions= restart/0/restart/30000//

Write-Host "Disable StartService ScheduledTask"
Get-ScheduledTask -TaskName  "StartService" | Enable-ScheduledTask
