function currentTimeoutValues {
    $currentSessionStateTimeout = (Get-WebConfigurationProperty -filter system.web/sessionState -name Timeout -PSPath "IIS:\Sites\Default Web Site\Blaise").Value
    $currentIdleTimeout = (Get-ItemProperty ("IIS:\AppPools\BlaiseAppPool")).processModel.idleTimeout
    return $currentSessionStateTimeout, $currentIdleTimeout
}

function timeoutIsSetCorrectly {
    param (
        [string] $currentSessionTimeout,
        [string] $currentIdleTimeout,
        [string] $expectedTimeout
    )
    ($currentSessionTimeout -eq $expectedTimeout) -and ($currentIdleTimeout -eq $expectedTimeout)
}

function setTimeoutValues{
    [string] $expectedTimeout = "08:00:00"
    $currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues
    $setTimeout = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout
        if ($setTimeout -eq $false){
            try{
            Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\Blaise" -Name "Timeout" -Value:$expectedTimeout
            }
            catch{
                Write-Host "Could not set session state time-out"
                Write-Host $_.ScriptStackTrace
                exit 1
            }
            try{
                Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value $expectedTimeout
            }
            catch{
                Write-Host "Could not set IIS idle time-out"
                Write-Host $_.ScriptStackTrace
                exit 1
            }
            Write-Host "Changes made to timeouts - Restart required"
            Restart-WebAppPool BlaiseAppPool
            Write-Host "BlaiseAppPool has been restarted"
        }
        else {
            Write-Host "No changes necessary to timeouts - Restart not required"
        }
}




