function Install_StackDriver_Logging() {
    Write-Host "Checking if target logging agent version has been installed already..."
    if (Test-Path C:\dev\data\$($LoggingAgent)) {
        Write-Host "Version already installed, checking it has been started"
        if (Get-Service "StackdriverLogging" | Where-Object {$_.Status -eq "Running"}) {
            Write-Host "Already started, nothing to do..."
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

function Uninstall_OpsAgent() {
    Write-Host "Uninstalling Ops Agent"
    googet -noconfirm remove google-cloud-ops-agent
}

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

param ([string]$LoggingAgent)

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Google Cloud Ops Agent running..."
    Uninstall_OpsAgent
    Install_StackDriver_Logging
}
elseif (Check_Service StackdriverMonitoring) {
    Write-Host "Stackdriver Monitoring Agent is running"
}
else {
    Write-Host "No evidence of agents found, installing Stackdriver Logging and Monitoring"
    Install_StackDriver_Logging
}

exit 0