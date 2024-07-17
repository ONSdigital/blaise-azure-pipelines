. "$PSScriptRoot\..\logging_functions.ps1"

param ($exeName, $ServiceName)

LogInfo("Creating Windows service $ServiceName")
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

LogInfo("Adding recovery options to Windows service $ServiceName")
sc.exe failure $ServiceName reset= 1 actions= restart/60000/run/1000

LogInfo("Adding delayed start to Windows service $ServiceName")
sc.exe config $ServiceName start= delayed-auto

LogInfo("Starting Windows service $ServiceName")
sc.exe start $ServiceName

LogInfo("Adding secondary recovery options to Windows service $ServiceName")
sc.exe failure $ServiceName reset= 7200 actions= restart/0/restart/30000//
