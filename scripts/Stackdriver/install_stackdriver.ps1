param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

function Install_StackDriver_Logging() {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_args = "/S /D='C:\dev\stackdriver\loggingagent'"
    Start-Process -Wait "C:\dev\data\$($loggingagent)" -ArgumentList $logging_args

    if (Check_Service StackdriverLogging) {
        Write-Host "Stackdriver Logging Agent is running"
    }
}

function Install_StackDriver_Monitoring() {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_args = "/S /D='C:\dev\stackdriver\monitoringAgent'"
    Start-Process -Wait "C:\dev\data\$($monitoringagent)" -ArgumentList $monitoring_args
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

Write-Host "DEBUG: Target logging agent is: $loggingagent"
Write-Host "DEBUG: Target monitoring agent is: $monitoringagent"
Write-Host "DEBUG: GCP artifact bucket is: $GCP_BUCKET"

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Attempting to uninstall Ops Agent..."
    Uninstall_OpsAgent
}
elseif (-Not Check_Service StackdriverMonitoring) {
    Write-Host "Attempting to install Stackdriver Monitoring agent..."
    Install_StackDriver_Monitoring
}
elseif (-Not Check_Service StackdriverLogging) {
    Write-Host "Attempting to install Stackdriver Logging agent..."
    Install_StackDriver_Logging
}
else {
    Write-Host "No evidence of agents found, installing Stackdriver Logging and Monitoring"
    Install_StackDriver_Logging
    Install_StackDriver_Monitoring
}

exit 0