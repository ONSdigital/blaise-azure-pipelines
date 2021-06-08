param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

Write-Host "Checking if target logging agent version has been installed already..."
if (Test-Path C:\dev\data\$($loggingagent)) {
    Write-Host "Version already installed, checking it has been started"
    if (Get-Service "StackdriverLogging" | Where-Object {$_.Status -eq "Running"}) {
        Write-Host "Already started, nothing to do..."
    }
    elseif (Get-Service "StackdriverLogging" | Where-Object {$_.Status -eq "Stopped"}) {
        Write-Host "Starting service"
        Start-Service "StackdriverLogging"
    }
    else {
        Write-Host "Error, service not found..."
        exit 1
    }
}
else {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_args = "/S /D='C:\dev\stackdriver\loggingAgent'"
    Start-Process -Wait "C:\dev\data\$($loggingagent)" -ArgumentList $logging_args
}

Write-Host "Checking if target monitoring agent version has been installed already..."
if (Test-Path C:\dev\data\$monitoringagent) {
    Write-Host "Version already installed, skipping..."
    if (Get-Service "StackdriverMonitoring" | Where-Object {$_.Status -eq "Running"}) {
        Write-Host "Already started, nothing to do..."
    }
    elseif (Get-Service "StackdriverMonitoring" | Where-Object {$_.Status -eq "Stopped"}) {
        Write-Host "Starting service"
        Start-Service "StackdriverMonitoring"
    }
    else {
        Write-Host "Error, service not found..."
        exit 1
    }
}
else {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_args = "/S /D='C:\dev\stackdriver\monitoringAgent'"
    Start-Process -Wait "C:\dev\data\$($monitoringagent)" -ArgumentList $monitoring_args
}

Write-Host "Agent Installation Completed"

exit 0
