. "$PSScriptRoot\..\logging_functions.ps1"
. "$PSScriptRoot\..\blaise\install_cma_packages.ps1"

function Get-BlaiseRegistryKey {
    return Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -match 'blaise' } 
}

function Update-CmaRegistry {
    param (
        [string]$PackageValue
    )
    $Blaise = Get-BlaiseRegistryKey
    if (-not $Blaise.PSPath) {
        return $false
    }

    $maxAttempts = 3
    $attempt = 1

    while ($attempt -le $maxAttempts) {
        try {
            LogInfo("Attempt $attempt of $maxAttempts to update CMA registry")
            Set-ItemProperty -Path $Blaise.PSPath -Name "CMAInstalledPackage" -Value $PackageValue
            return $true
        }
        catch {
            LogError("Attempt $attempt to update CMA registry failed: $_")
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Seconds 2
            }
            $attempt++
        }
    }

    LogError("Failed to update CMA registry after $maxAttempts attempts.  CMA registry NOT updated")
    return $false
}

function Install-Cma-With-Retry {
    param (
        [bool]$CreateDatabaseTables
    )

    $maxAttempts = 3
    $attempt = 1
    while ($attempt -le $maxAttempts) {
        try {
            LogInfo("Attempt $attempt of $maxAttempts to install CMA packages (CreateDatabaseTables=$CreateDatabaseTables)")
            $success = Install-Cma-Packages -CreateDatabaseTables "$CreateDatabaseTables"
            if ($success -eq $true) {
                LogInfo("CMA install succeeded on attempt $attempt")
                Update-CmaRegistry -PackageValue $env:ENV_CMA_MULTI_PACKAGE | Out-Null
                return $true
            } else {
                throw "Install-Cma-Packages returned false"
            }
        } catch {
            LogError("Attempt $attempt to install CMA failed: $_")
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Seconds 2
            }
            $attempt++
        }
    }

    LogInfo("CMA install failed after $maxAttempts attempts. CMA NOT installed")
    return $false
}

function VerifyCmaIsInstalled{
    $Blaise = Get-BlaiseRegistryKey
    $installedCmaPackage = $Blaise.CMAInstalledPackage

    if(!$installedCmaPackage){
        LogInfo("CMA is not installed")
        Install-Cma-With-Retry -CreateDatabaseTables $true | Out-Null
    } else {
        LogInfo("CMA $installedCmaPackage installed")

        if($installedCmaPackage -eq $env:ENV_CMA_MULTI_PACKAGE) {
            LogInfo("CMA multi-package version already installed")
        } else {
            LogInfo("CMA multi-package version needs to be changed")
            Install-Cma-With-Retry -CreateDatabaseTables $false | Out-Null
        }
    }

}

VerifyCmaIsInstalled