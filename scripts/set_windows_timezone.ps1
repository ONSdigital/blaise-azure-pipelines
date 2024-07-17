# Used to ensure VMs are all set to correct time zone

$currentTimeZone = Get-TimeZone

if ($currentTimeZone.Id -eq $env:Blaise_TimeZone)
{
    Write-Host "Time zone already correct - $($currentTimeZone.Id)"
}
else {
    Write-Host "Time zone incorrect - $($currentTimeZone.Id)"

    Set-TimeZone -Id $env:Blaise_TimeZone -PassThru

    if (Get-Command Get-IISAppPool -ErrorAction SilentlyContinue)
    {
        $allAppPools = Get-IISAppPool

        foreach($appPool in $allAppPools.name)
        {
            Write-Host "Restarting app pool $($appPool)"
            Restart-WebAppPool -Name $appPool
        }
    }
    else {
        Write-Host "IIS is not installed"
    }

    $newTimeZone = Get-TimeZone

    Write-Host "Time zone updated - $($newTimeZone)"
}
