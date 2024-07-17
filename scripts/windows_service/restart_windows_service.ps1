param ($ServiceName)

. "$PSScriptRoot\logging_functions.ps1"

try{
    LogInfo("Restarting Windows service $ServiceName")
    restart-service $ServiceName
    LogInfo("Windows service $ServiceName restarted")
}

catch{
    LogError("Could not restart $ServiceName Windows service")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
