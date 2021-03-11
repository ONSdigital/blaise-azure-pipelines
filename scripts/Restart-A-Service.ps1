param ($ServiceName)

try{
restart-service $ServiceName
Write-Host "Restarted Blaise Service"
}

catch{
Write-Host "Could Not Restart Blaise Service"
}