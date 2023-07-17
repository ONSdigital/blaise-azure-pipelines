# Used to ensure VMs are all set to correct time zone

$currentTimeZone = Get-TimeZone

if ($currentTimeZone.Id -eq $env:Blaise_TimeZone)
{
    Write-Information "Time Zone is set correct to $($currentTimeZone.Id)"
}
else {
    Write-Information "Time zone is not correct $($currentTimeZone.Id)"

    Set-TimeZone -Id $env:Blaise_TimeZone -PassThru

    if (Get-Command Get-IISAppPool -ErrorAction SilentlyContinue)
    {
        $allAppPools = Get-IISAppPool

        foreach($appPool in $allAppPools.name)
        {
            Restart-WebAppPool -Name $appPool
            Write-Information "Restarted: $($appPool)"
        }
    }
    else {
        Write-Information "IIS is not on this box"
    }

    $newTimeZone = Get-TimeZone

    Write-Information "Timezone set to $($newTimeZone)"
}
