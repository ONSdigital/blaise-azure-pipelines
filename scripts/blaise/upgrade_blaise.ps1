. "$PSScriptRoot\..\logging_functions.ps1"

$blaiseInstallDir = "C:\dev\data\Blaise"
$blaiseGcpBucket = $env:ENV_BLAISE_GCP_BUCKET
$blaiseInstallPackage = $env:ENV_BLAISE_INSTALL_PACKAGE
$blaiseAdminUser = $env:ENV_BLAISE_ADMIN_USER
$blaiseAdminPassword = $env:ENV_BLAISE_ADMIN_PASSWORD

$dashboardFolders = @(
    "D:\Blaise5\Blaise"
    "D:\Blaise5\BlaiseDashboard"
)

function Download-BlaiseInstaller {
    LogInfo("Downloading Blaise installer")
    gsutil cp "gs://$blaiseGcpBucket/$blaiseInstallPackage" "C:\dev\data"
}

function Unzip-BlaiseInstaller {
    LogInfo("Unzipping Blaise installer")
    Remove-Item $blaiseInstallDir -Recurse -ErrorAction Ignore
    mkdir $blaiseInstallDir
    Expand-Archive -Force "C:\dev\data\$blaiseInstallPackage" $blaiseInstallDir
}

function Uninstall-Blaise {
    LogInfo("Uninstalling Blaise")
    $blaiseUninstallArgs = @(
        "/qn"
        "/norestart"
        "/log C:\dev\data\Blaise\upgrade.log"
        "/x {24691BB5-A1CE-455B-A2D5-FBDE1CE10675}"
    )
    Start-Process -Wait "msiexec" -ArgumentList $blaiseUninstallArgs
}

function Delete-DashboardFolders {
    LogInfo("Deleting dashboard folders")
    foreach ($folder in $dashboardFolders) {
        if (Test-Path -Path $folder) {
            LogInfo("Folder found: $folder")
            try {
                Remove-Item -Path $folder -Recurse -Force
                LogInfo("Folder successfully deleted: $folder")
            }
            catch {
                LogError("Error deleting folder $folder")
                LogError("$($_.Exception.Message)")
                LogError("$($_.ScriptStackTrace)")
            }
        }
        else {
            LogInfo("Folder does not exist: $folder")
        }
    }
}

function Upgrade-Blaise {
    LogInfo("Upgrading Blaise")
    $blaiseUpgradeArgs = @(
        "/qn"
        "/norestart"
        "/log upgrade.log"
        "/i C:\dev\data\Blaise\Blaise5.msi"
    )
    $blaiseUpgradeArgs += "FORCEINSTALL=1"
    $blaiseUpgradeArgs += "INSTALLATIONMODE=Upgrade"
    $blaiseUpgradeArgs += "ADMINISTRATORUSER=$blaiseAdminUser"
    $blaiseUpgradeArgs += "ADMINISTRATORPASSWORD=$blaiseAdminPassword"
    Start-Process -Wait "msiexec" -ArgumentList $blaiseUpgradeArgs
}

LogInfo("Upgrading Blaise to version $env:ENV_BLAISE_CURRENT_VERSION")

Download-BlaiseInstaller
Unzip-BlaiseInstaller
Uninstall-Blaise
Delete-DashboardFolders
Upgrade-Blaise

LogInfo("Blaise upgrade complete")
