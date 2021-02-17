$folderPath = "c:\dev\data\Blaise"

Write-Host "Download Blaise redistributables"
gsutil cp gs://$BLAISE_GCP_BUCKET/$env:BLAISE_VERSION.zip "C:\dev\data"

Write-Host "Expand archive to 'Blaise' dir"
Remove-Item $folderPath -Recurse -ErrorAction Ignore
mkdir $folderPath

Expand-Archive -Force C:\dev\data\$env:BLAISE_VERSION.zip C:\dev\data\Blaise\
Write-Host "Setting Blaise uninstall args"
$blaise_args = "/qn","/norestart","/log C:\dev\data\Blaise\upgrade.log","/x {24691BB5-A1CE-455B-A2D5-FBDE1CE10675}"
Write-Host "blaise_args: $blaise_args"
Write-Host "Running msiexec for Blaise uninstall"
Start-Process -Wait "msiexec" -ArgumentList $blaise_args
Write-Host "Blaise uninstall complete"

Write-Host "Setting Blaise upgrade args"
$blaise_args = "/qn","/norestart","/log upgrade.log","/i C:\dev\data\Blaise\Blaise5.msi"
$blaise_args += "FORCEINSTALL=1"
$blaise_args += "INSTALLATIONMODE=Upgrade"
Write-Host "blaise_args: $blaise_args"
Write-Host "Running msiexec for Blaise upgrade"
Start-Process -Wait "msiexec" -ArgumentList $blaise_args
Write-Host "Blaise upgrade complete"
