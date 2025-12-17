param ([string]$GCP_BUCKET)

. "$PSScriptRoot\logging_functions.ps1"

$targetVersion = "9.5.0"
$installerFileName = "mysql-connector-net-$targetVersion.msi"
$localInstallerPath = "C:\dev\data\$installerFileName"

LogInfo("Checking for existing MySQL Connector installation...")

$isInstalled = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | 
               Get-ItemProperty | 
               Where-Object { 
                   ($_.DisplayName -like "*MySQL Connector*") -and 
                   ($_.DisplayVersion -eq $targetVersion) 
               }

if ($isInstalled) {
    LogInfo("MySQL Connector $targetVersion already installed, skipping...")
}
else {
    LogInfo("MySQL Connector $targetVersion not found, installing...")

    $installDir = Split-Path $localInstallerPath -Parent
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    if (-not (Test-Path $localInstallerPath)) {
        LogInfo("Downloading MySQL Connector installer...")
        gsutil cp "gs://$GCP_BUCKET/$installerFileName" "$localInstallerPath"
    } else {
        LogInfo("MySQL Connector installer already downloaded")
    }

    LogInfo("Installing $installerFileName...")
    $process = Start-Process msiexec.exe -Wait -ArgumentList "/I `"$localInstallerPath`" /quiet /norestart" -PassThru

    if ($process.ExitCode -eq 0) {
        LogInfo("Installation successful")

        try {
            $blaiseServices = @(Get-Service -Name "Blaise*" -ErrorAction SilentlyContinue)
            if ($blaiseServices.Count -gt 0) {
                foreach ($service in $blaiseServices) {
                    LogInfo("Restarting service: $($service.Name)")
                    Restart-Service -Name $service.Name
                    LogInfo("Service $($service.Name) restarted successfully")
                }
            } else {
                LogInfo("Blaise service not found...")
            }
        }
        catch {
            LogError("Failed to restart ($service.Name) service: $($_.Exception.Message)")
            exit 1
        }
    } else {
        LogError("Installation failed with exit code: $($process.ExitCode)")
        exit 1
    }
}
