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

function setTimeoutValues {
    [string] $expectedTimeout = "08:00:00"

    $sites = @(
        @{ SiteName = "Blaise"; AppPool = "BlaiseAppPool" },
        @{ SiteName = "BlaiseDashboard"; AppPool = "BlaiseDashboardAppPool" }
    )

    $existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$($_.SiteName)" }

    if (-not $existingSites) {
        throw "Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists"
    }

    foreach ($site in $existingSites) {
        $siteName = $site.SiteName
        $appPool  = $site.AppPool

        $currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues -siteName $siteName -appPoolName $appPool
        $setTimeout = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout

        if (-not $setTimeout) {
            Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\$siteName" -Name "Timeout" -Value:$expectedTimeout
            Set-ItemProperty ("IIS:\AppPools\$appPool") -Name processModel.idleTimeout -value $expectedTimeout

            LogInfo("IIS timeout changes made, restarting $appPool...")
            Restart-WebAppPool $appPool
            LogInfo("$appPool has been restarted")
        }
        else {
            LogInfo("IIS timeout changes already applied for $siteName / $appPool")
        }
    }
}
