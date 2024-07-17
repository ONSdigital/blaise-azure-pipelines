. "$PSScriptRoot\..\logging_functions.ps1"

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
                LogError("Could not set IIS session state timeout")
                LogError("$($_.Exception.Message)")
                LogError("$($_.ScriptStackTrace)")
                exit 1
            }
            try{
                Set-ItemProperty ("IIS:\AppPools\BlaiseAppPool") -Name processModel.idleTimeout -value $expectedTimeout
            }
            catch{
                LogError("Could not set IIS idle timeout")
                LogError("$($_.Exception.Message)")
                LogError("$($_.ScriptStackTrace)")
                exit 1
            }
            LogInfo("IIS timeout changes made, restarting BlaiseAppPool...")
            Restart-WebAppPool BlaiseAppPool
            LogInfo("BlaiseAppPool has been restarted")
        }
        else {
            LogInfo("IIS timeout changes already applied")
        }
}