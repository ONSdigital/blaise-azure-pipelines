$currentPath = Get-Location
$Blaise = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version
if (!$Blaise) {
    Write-Output "Blaise is not installed"
    Invoke-Expression "$currentPath\scripts\blaise\install_blaise.ps1"
}
else {
    Write-Output "Blaise Version " + $Blaise.DisplayVersion + " is installed"
    if ($Blaise.DisplayVersion -eq $env:ENV_BLAISE_CURRENT_VERSION) {
        Write-Output "Blaise is currently on the correct version, my work is done"
    }
    else {
        Write-Output "Blaise needs to be upgraded to the latest version"
        Invoke-Expression "$currentPath\scripts\blaise\upgrade_blaise.ps1"
    }
}