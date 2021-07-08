# Used to ensure VMs are all set to correct time zone

$currentTimeZone = Get-TimeZone

if ($currentTimeZone -eq $env:Blaise_TimeZone)
{
    Write-Host "Time Zone is set correct to $($currentTimeZone)"
}
else {
    Write-Host "Time zone is not correct $($currentTimeZone)"

    Set-TimeZone -Id $env:Blaise_TimeZone -PassThru

    if (Get-Command Get-IISAppPool -ErrorAction SilentlyContinue)
    {
        $allAppPools = Get-IISAppPool

        foreach($appPool in $allAppPools.name)
        {
            Restart-WebAppPool -Name $appPool
            Write-Host "Restarted: $($appPool)"
        }
    }
    else {
        Write-Host "IIS is not on this box"
    }

    $newTimeZone = Get-TimeZone

    Write-Host "Timezone set to $($newTimeZone)"
}
