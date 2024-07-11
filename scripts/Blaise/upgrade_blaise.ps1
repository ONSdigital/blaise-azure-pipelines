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
    Write-Host "Downloading Blaise installer"
    gsutil cp "gs://$blaiseGcpBucket/$blaiseInstallPackage" "C:\dev\data"
}

function Unzip-BlaiseInstaller {
    Write-Host "Unzipping Blaise installer"
    Remove-Item $blaiseInstallDir -Recurse -ErrorAction Ignore
    mkdir $blaiseInstallDir
    Expand-Archive -Force "C:\dev\data\$blaiseInstallPackage" $blaiseInstallDir
}

function Uninstall-Blaise {
    Write-Host "Uninstalling Blaise"
    $blaiseArgs = @(
        "/qn"
        "/norestart"
        "/log C:\dev\data\Blaise\upgrade.log"
        "/x {24691BB5-A1CE-455B-A2D5-FBDE1CE10675}"
    )
    Start-Process -Wait "msiexec" -ArgumentList $blaiseArgs
}

function Delete-DashboardFolders {
    Write-Host "Deleting dashboard folders"
    foreach ($folder in $dashboardFolders) {
        if (Test-Path -Path $folder) {
            Write-Host "Folder found: $folder"
            try {
                Remove-Item -Path $folder -Recurse -Force
                Write-Host "Folder successfully deleted: $folder"
            } catch {
                Write-Host "Error occurred while deleting folder: $folder"
            }
        } else {
            Write-Host "Folder does not exist: $folder"
        }
    }
}

function Upgrade-Blaise {
    Write-Host "Upgrading Blaise"
    $blaiseArgs = @(
        "/qn"
        "/norestart"
        "/log upgrade.log"
        "/i C:\dev\data\Blaise\Blaise5.msi"
    )
    $blaiseArgs += "FORCEINSTALL=1"
    $blaiseArgs += "INSTALLATIONMODE=Upgrade"
    $blaiseArgs += "ADMINISTRATORUSER=$blaiseAdminUser"
    $blaiseArgs += "ADMINISTRATORPASSWORD=$blaiseAdminPassword"
    Start-Process -Wait "msiexec" -ArgumentList $blaiseArgs
}

Write-Host "Upgrading Blaise to version: $env:ENV_BLAISE_CURRENT_VERSION"

Download-BlaiseInstaller
Unzip-BlaiseInstaller
Uninstall-Blaise
Delete-DashboardFolders
Upgrade-Blaise

Write-Host "Blaise upgrade complete 👍"