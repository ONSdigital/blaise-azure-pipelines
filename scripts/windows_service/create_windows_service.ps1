param ($exeName, $ServiceName)

. "$PSScriptRoot\..\logging_functions.ps1"

LogInfo("Creating Windows service $ServiceName")
sc.exe create $ServiceName binpath=C:\BlaiseServices\$ServiceName\$exeName.exe

LogInfo("Adding recovery options to Windows service $ServiceName")
sc.exe failure $ServiceName reset=0 actions=restart/1000

LogInfo("Adding delayed start to Windows service $ServiceName")
sc.exe config $ServiceName start=delayed-auto

LogInfo("Starting Windows service $ServiceName")
sc.exe start $ServiceName
