param ($ServiceName)

try{
    restart-service $ServiceName
    Write-Host "Restarted $ServiceName Service"
}

catch{
    Write-Host "Could Not Restart $ServiceName Service"
    Write-Host $_.ScriptStackTrace
    exit 1
}
