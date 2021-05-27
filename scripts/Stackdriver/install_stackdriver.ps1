param ($loggingagent, $monitoringagent, $GCP_BUCKET)

Write-Host "Checking if target logging agent version has been installed already..."
if (Test-Path C:\dev\stackdriver\$loggingagent) {
    Write-Host "Version already installed, skipping..."
}
else {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$loggingagent"

    Write-Host "Installing Stackdriver logging agent..."
    C:\dev\stackdriver\$loggingagent /S /D="C:\dev\stackdriver\loggingAgent"
}

Write-Host "Checking if target monitoring agent version has been installed already..."
if (Test-Path C:\dev\stackdriver\$monitoringagent) {
    Write-Host "Version already installed, skipping..."
}
else {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$monitoringagent"

    Write-Host "Installing Stackdriver monitoring agent..."
    C:\dev\stackdriver\$monitoringagent /S /D="C:\dev\stackdriver\monitoringAgent"
}
