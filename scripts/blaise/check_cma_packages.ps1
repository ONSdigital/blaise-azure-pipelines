. "$PSScriptRoot\..\logging_functions.ps1"

$CurrentPath = Get-Location

$Blaise = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -match 'blaise' } | Select-Object CMAInstalledPackage

if (!$Blaise.CMAInstalledPackage) {
    LogInfo("CMA is not installed")
    . "$CurrentPath\scripts\blaise\install_cma_packages.ps1"
    Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -Name "CMAInstalledPackage" -Value $env:ENV_CMA_MULTI_PACKAGE | Where-Object { $_.DisplayName -match 'blaise' }
}
else {
    
    $CMAInstalledPackage = $Blaise.CMAInstalledPackage
    LogInfo("CMA $CMAInstalledPackage installed")
    if ($Blaise.CMAInstalledPackage -eq $env:ENV_CMA_MULTI_PACKAGE) {
        "CMA mutli package version already installed"
    }
    else {
        LogInfo("CMA mutli package version needs to be changed")
        . "$CurrentPath\scripts\blaise\install_cma_packages.ps1"
    }
}