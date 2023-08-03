function currentTimeoutValues {
    $currentSessionStateTimeout = (Get-WebConfigurationProperty -filter system.web/sessionState -name Timeout -PSPath "IIS:\Sites\Default Web Site\Blaise")
    Write-Host "Session timeout is currently: $currentSessionStateTimeout"
    $currentIdleTimeout = (Get-ItemProperty ("IIS:\AppPools\BlaiseAppPool")).processModel.idleTimeout
    Write-Host "Idle timeout is currently: $currentIdleTimeout"
}

try{
    Write-Host "Getting current timeouts"
    currentTimeoutValues
    Write-Host "Setting session state time-out"
    Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\Blaise" -Name "Timeout" -Value:08:00:00
    Write-Host "Session time-out set"
}
catch{
    Write-Host "Could not set session state time-out"
    Write-Host $_.ScriptStackTrace
    exit 1
}

try{
    Write-Host "Setting ISS idle time-out"
    Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(480))
    Write-Host "ISS idle set"
}
catch{
    Write-Host "Could not set ISS idle time-out"
    Write-Host $_.ScriptStackTrace
    exit 1
}

try
{
    Write-Host "Restarting BlaiseAppPool"
    Restart-WebAppPool BlaiseAppPool
    Write-Host "BlaiseAppPool has been restarted"
}
catch{
    Write-Host "Unable to restart BlaiseAppPool"
    exit 1
}