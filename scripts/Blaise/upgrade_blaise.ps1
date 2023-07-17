$folderPath = "c:\dev\data\Blaise"

Write-Information "Upgrade blaise to version: $env:ENV_BLAISE_CURRENT_VERSION"

Write-Information "Download Blaise redistributables"
gsutil cp gs://$env:ENV_BLAISE_GCP_BUCKET/$env:ENV_BLAISE_INSTALL_PACKAGE "C:\dev\data"

Write-Information "Expand archive to 'Blaise' dir"
Remove-Item $folderPath -Recurse -ErrorAction Ignore
mkdir $folderPath

Expand-Archive -Force C:\dev\data\$env:ENV_BLAISE_INSTALL_PACKAGE C:\dev\data\Blaise\
Write-Information "Setting Blaise uninstall args"
$blaise_args = "/qn","/norestart","/log C:\dev\data\Blaise\upgrade.log","/x {24691BB5-A1CE-455B-A2D5-FBDE1CE10675}"
Write-Information "blaise_args: $blaise_args"
Write-Information "Running msiexec for Blaise uninstall"
Start-Process -Wait "msiexec" -ArgumentList $blaise_args
Write-Information "Blaise uninstall complete"

Write-Information "Blaise admin user: $env:ENV_BLAISE_ADMIN_USER"
Write-Information "Blaise admin password: $env:ENV_BLAISE_ADMIN_PASSWORD"
Write-Information "Setting Blaise upgrade args"
$blaise_args = "/qn","/norestart","/log upgrade.log","/i C:\dev\data\Blaise\Blaise5.msi"
$blaise_args += "FORCEINSTALL=1"
$blaise_args += "INSTALLATIONMODE=Upgrade"
$blaise_args += "ADMINISTRATORUSER=$env:ENV_BLAISE_ADMIN_USER"
$blaise_args += "ADMINISTRATORPASSWORD=$env:ENV_BLAISE_ADMIN_PASSWORD"
Write-Information "blaise_args: $blaise_args"
Write-Information "Running msiexec for Blaise upgrade"
Start-Process -Wait "msiexec" -ArgumentList $blaise_args
Write-Information "Blaise upgrade complete"
