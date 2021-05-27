param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

Write-Host "Checking if target logging agent version has been installed already..."
if (Test-Path C:\dev\stackdriver\$($loggingagent)) {
    Write-Host "Version already installed, skipping..."
}
else {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_install = "C:\dev\data\stackdriver\$($loggingagent) /S /D='C:\dev\stackdriver\loggingAgent'"
    & cmd /c $logging_install
}

Write-Host "Checking if target monitoring agent version has been installed already..."
if (Test-Path C:\dev\stackdriver\$monitoringagent) {
    Write-Host "Version already installed, skipping..."
}
else {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_install = "C:\dev\data\stackdriver\$($monitoringagent) /S /D='C:\dev\stackdriver\monitoringAgent'"
    & cmd /c $monitoring_install
}

Write-Host "Agent Installation Completed"

exit 0
