param ($ServiceName)

try{
    restart-service $ServiceName
    Write-Output "Restarted $ServiceName Service"
}

catch{
    Write-Output "Could Not Restart $ServiceName Service"
    Write-Output $_.ScriptStackTrace
    exit 1
}
