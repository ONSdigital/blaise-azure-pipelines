Write-Host "Creating Service"
sc.exe create $(Build.DefinitionName) binpath=C:\BlaiseServices\$(Build.DefinitionName)\$(Build.DefinitionName).exe

Write-Host "Adding Recovery options"
sc.exe failure $(Build.DefinitionName) reset= 1 actions= restart/60000/run/1000
sc.exe failure $(Build.DefinitionName) command= "\"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe\"Powershell -c C:\dev\stackdriver\logsServiceFailure.ps1 -ServiceName $(Build.DefinitionName)"

Write-Host "Adding Delayed start to the service"
sc.exe config $(Build.DefinitionName) start= delayed-auto

Write-Host "Starting the service"
sc.exe start $(Build.DefinitionName)

Write-Host "Adding Secondary recovery options"
sc.exe failure $(Build.DefinitionName) reset= 7200 actions= restart/0/restart/30000//

Write-Host "Disable StartService ScheduledTask"
Get-ScheduledTask -TaskName  "StartService" | Enable-ScheduledTask
