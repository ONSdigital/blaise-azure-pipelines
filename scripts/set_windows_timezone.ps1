. "$PSScriptRoot\logging_functions.ps1"

$currentTimeZone = Get-TimeZone

if ($currentTimeZone.Id -eq $env:Blaise_TimeZone)
{
    LogInfo("Time zone already correct - $($currentTimeZone.Id)")
}
else {
    LogInfo("Time zone incorrect - $($currentTimeZone.Id)")

    Set-TimeZone -Id $env:Blaise_TimeZone -PassThru

    if (Get-Command Get-IISAppPool -ErrorAction SilentlyContinue)
    {
        $allAppPools = Get-IISAppPool

        foreach($appPool in $allAppPools.name)
        {
            LogInfo("Restarting app pool $($appPool)")
            Restart-WebAppPool -Name $appPool
        }
    }
    else {
        LogInfo("IIS is not installed")
    }

    $newTimeZone = Get-TimeZone

    LogInfo("Time zone updated - $($newTimeZone)")
}
