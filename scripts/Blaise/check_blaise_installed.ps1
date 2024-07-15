$CurrentPath = Get-Location
$Blaise = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version
if (!$Blaise) {
    Write-Host "Blaise is not installed"
    . "$CurrentPath\scripts\blaise\install_blaise.ps1"
}
else {
    $BlaiseVersion = $Blaise.DisplayVersion
    Write-Host "Blaise version $BlaiseVersion is installed"
    if ($Blaise.DisplayVersion -eq $env:ENV_BLAISE_CURRENT_VERSION) {
        "Blaise is already on the correct version"
    }
    else {
        Write-Host "Blaise version needs to be changed"
        . "$CurrentPath\scripts\blaise\upgrade_blaise.ps1"
    }
}