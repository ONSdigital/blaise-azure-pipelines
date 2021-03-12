param ($ServiceName)

try{
    restart-service $ServiceName
    Write-Host "Restarted Blaise Service"
}

catch{
    Write-Host "Could Not Restart Blaise Service"
    Write-Host $_.ScriptStackTrace
    exit 1
}