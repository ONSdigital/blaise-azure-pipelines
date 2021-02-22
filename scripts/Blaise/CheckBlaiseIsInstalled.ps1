$currentPath = Split-Path $MyInvocation.InvocationName
$Blaise = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version 

if (!$Blaise){
    Write-Host "Blaise is not installed"
    Invoke-Expression "$currentPath/InstallBlaise.ps1"
}
else
{
Write-Host "Blaise Version " + $Blaise.DisplayVersion + " is installed"
    if ($Blaise.DisplayVersion -eq $env:ENV_BLAISE_CURRENT_VERSION)
    {
        Write-Host "Blaise is currently on the correct version, my work is done"
    }
    else {
        Write-Host "Blaise needs to be upgraded to the latest version"
        Invoke-Expression "$currentPath/UpgradeBlaise.ps1"     
    }
}
