param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

function Start_Service_If_Not_Running($ServiceName) {
    $service = Get-Service -Name $ServiceName

    if ($service.Status -ne 'Running') {
        Start-Service $service
    }
}

function Check_Service_Exists($ServiceName) {
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
        return $TRUE
    }
    return $FALSE
}

function Uninstall_Ops_Agent() {
    Write-Host "Attempting to uninstall Ops Agent..."
    googet -noconfirm remove google-cloud-ops-agent
}


function Uninstall_StackDriver_Logging() {
    if (Check_Service_Exists StackdriverLogging) {
        Write-Host "Stopping StackdriverLogging service"
        Stop-Service -Name StackdriverLogging
    }
}

function Install_StackDriver_Logging($loggingagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_args = "/S /D='C:\Program Files (x86)\stackdriver\loggingAgent'"
    Start-Process -Wait "C:\dev\data\$($loggingagent)" -ArgumentList $logging_args
}

function Install_StackDriver_Monitoring($monitoringagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_args = "/S /D='C:\Program Files (x86)\stackdriver\monitoringAgent'"
    Start-Process -Wait "C:\dev\data\$($monitoringagent)" -ArgumentList $monitoring_args
}

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

if (Check_Service_Exists google-cloud-ops-agent) {
    Uninstall_Ops_Agent
}

if (-not (Check_Service_Exists StackdriverLogging)) {
    Install_StackDriver_Logging $loggingagent $GCP_BUCKET
}

if (-not (Check_Service_Exists StackdriverMonitoring)) {
    Install_StackDriver_Monitoring $monitoringagent $GCP_BUCKET
}

