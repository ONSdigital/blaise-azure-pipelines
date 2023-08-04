function currentTimeoutValues {
    $currentSessionStateTimeout = (Get-WebConfigurationProperty -filter system.web/sessionState -name Timeout -PSPath "IIS:\Sites\Default Web Site\Blaise").Value
    Write-Host "Session timeout is currently: $currentSessionStateTimeout"
    $currentIdleTimeout = (Get-ItemProperty ("IIS:\AppPools\BlaiseAppPool")).processModel.idleTimeout
    Write-Host "Idle timeout is currently: $currentIdleTimeout"
    return $currentSessionStateTimeout, $currentIdleTimeout
}
function timeoutIsSetCorrectly {
    param (
        [string] $currentTimeout,
        [string] $expectedTimeout
    )
    Write-Host "current: $currentTimeout"
    Write-Host "expected: $expectedTimeout"
    return $currentTimeout -eq $expectedTimeout
}


[bool] $restartNeeded = $false
[string] $expectedTimeout = "09:00:00"
Write-Host "Getting current timeouts"
$currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues

try{    
    Write-Host "Checking session state time-out"
    $setTimeout = timeoutIsSetCorrectly -currentTimeout $currentSessionStateTimeout -expectedTimeout $expectedTimeout
    
    if (-Not $setTimeout){
        Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\Blaise" -Name "Timeout" -Value:$expectedTimeout
        $restartNeeded = $true
        Write-Host "Session time-out set, Restart required"
    }
    else {
        Write-Host "Timeout already set, Restart not required"
    }    
}
catch{
    Write-Host "Could not set session state time-out"
    Write-Host $_.ScriptStackTrace
    exit 1
}

try{
    Write-Host "Checking ISS idle time-out"
    $setTimeout = timeoutIsSetCorrectly -currentTimeout $currentSessionStateTimeout -expectedTimeout $expectedTimeout
    if (-Not $setTimeout){
        Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value $expectedTimeout
        $restartNeeded = $true
        Write-Host "IIS idle time-out set, Restart required"
    }
    else {
        Write-Host "Timeout already set, Restart not required"
    }   
}
catch{
    Write-Host "Could not set ISS idle time-out"
    Write-Host $_.ScriptStackTrace
    exit 1
}

currentTimeoutValues

try
{
    if ($restartNeeded){
        Write-Host "Restarting BlaiseAppPool"
        Restart-WebAppPool BlaiseAppPool
        Write-Host "BlaiseAppPool has been restarted"
    }
    else{
        Write-Host "BlaiseAppPool does not need to be restarted"
    }    
}
catch{
    Write-Host "Unable to restart BlaiseAppPool"
    exit 1
}