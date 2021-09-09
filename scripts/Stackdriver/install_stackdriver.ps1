param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

function Check_Service($Service_Name) {
    if (Get-Service $Service_Name -ErrorAction SilentlyContinue) {
        if (Get-Service $Service_Name | Where-Object {$_.Status -eq "Running"}) {
            Write-Host "$Service_Name already started"
            return $TRUE
        }
        else {
            Write-Host "Starting service $Service_Name"
            Start-Service -Name $Service_Name
            return $TRUE
        }
    }
    else {
        Write-Host "Service $Service_Name not found"
        return $FALSE
    }
}

function Install_StackDriver_Logging($loggingagent, $GCP_BUCKET) {
    Write-Host "Checking if target logging agent version has been installed already..."
    if (Test-Path C:\dev\data\$($loggingagent)) {
        Write-Host "'$($loggingagent)' already installed, checking it has been started"
        if (Get-Service "StackdriverLogging" | Where-Object {$_.Status -eq "Running"}) {
            Write-Host "Stackdriver Logging already started, nothing to do..."
        }
        elseif (Get-Service "StackdriverLogging" | Where-Object {$_.Status -eq "Stopped"}) {
            Write-Host "Starting service"
            Start-Service -Name "StackdriverLogging"
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
}

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Attempting to uninstall Ops Agent..."
    googet -noconfirm remove google-cloud-ops-agent
}

if (Check_Service StackdriverMonitoring) {
    Write-Host "DEBUG: What is going on with Stackdriver Monitoring!?"
}

Install_StackDriver_Logging $loggingagent $GCP_BUCKET

Write-Host "Agent installation completed attempting to start it"
try {
    Start-Service StackdriverLogging
    Write-Host "Started Successfully"
    exit 0
}
catch {
    Write-Host "Failed to start, this is typically caused by the legacy agents still existing!"
    exit 1
}


exit 0
