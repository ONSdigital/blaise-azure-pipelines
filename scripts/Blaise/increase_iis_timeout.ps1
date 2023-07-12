try{
    Write-Output "Setting session state time-out"
    Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\Blaise" -Name "Timeout" -Value:08:00:00
    Write-Output "Session time-out set"
}
catch{
    Write-Output "Could not set session state time-out"
    Write-Output $_.ScriptStackTrace
    exit 1
}

try{
    Write-Output "Setting ISS idle time-out"
    Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(480))
    Write-Output "ISS idle set"
}
catch{
    Write-Output "Could not set ISS idle time-out"
    Write-Output $_.ScriptStackTrace
    exit 1
}

try
{
    Write-Output "Restarting BlaiseAppPool"
    Restart-WebAppPool BlaiseAppPool
    Write-Output "BlaiseAppPool has been restarted"
}
catch{
    Write-Output "Unable to restart BlaiseAppPool"
    exit 1
}