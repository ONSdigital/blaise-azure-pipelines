param ($ServiceName)

try{
    Write-Host "Restarting Windows service $ServiceName"
    restart-service $ServiceName
    Write-Host "Windows service $ServiceName restarted"
}

catch{
    Write-Host "Could not restart $ServiceName Windows service"
    Write-Host $_.ScriptStackTrace
    exit 1
}
