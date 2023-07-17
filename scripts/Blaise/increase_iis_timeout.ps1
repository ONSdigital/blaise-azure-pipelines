try{
    Write-Information "Setting session state time-out"
    Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\Blaise" -Name "Timeout" -Value:08:00:00
    Write-Information "Session time-out set"
}
catch{
    Write-Information "Could not set session state time-out"
    Write-Information $_.ScriptStackTrace
    exit 1
}

try{
    Write-Information "Setting ISS idle time-out"
    Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(480))
    Write-Information "ISS idle set"
}
catch{
    Write-Information "Could not set ISS idle time-out"
    Write-Information $_.ScriptStackTrace
    exit 1
}

try
{
    Write-Information "Restarting BlaiseAppPool"
    Restart-WebAppPool BlaiseAppPool
    Write-Information "BlaiseAppPool has been restarted"
}
catch{
    Write-Information "Unable to restart BlaiseAppPool"
    exit 1
}