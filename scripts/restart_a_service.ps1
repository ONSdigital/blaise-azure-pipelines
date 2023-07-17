param ($ServiceName)

try{
    restart-service $ServiceName
    Write-Information "Restarted $ServiceName Service"
}

catch{
    Write-Information "Could Not Restart $ServiceName Service"
    Write-Information $_.ScriptStackTrace
    exit 1
}
