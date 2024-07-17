param ([string]$GCP_BUCKET)

if (Test-Path C:\dev\data\mysql-connector-net-8.0.22.msi) {
    Write-Host "MySQL connector already installed, skipping..."
}
else {
    Write-Host "Downloading and installing MySQL connector..."
    gsutil cp gs://$GCP_BUCKET/mysql-connector-net-8.0.22.msi "C:\dev\data\mysql-connector-net-8.0.22.msi"
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\mysql-connector-net-8.0.22.msi /quiet'
}