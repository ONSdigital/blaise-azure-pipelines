param ([string]$loggingagent, [string]$monitoringagent, [string]$GCP_BUCKET)

function Check_Service_Exists($Service_Name) {
    if (Get-Service $Service_Name -ErrorAction SilentlyContinue) {
        return $TRUE
    }
    return $FALSE
}

function Uninstall_Ops_Agent() {
    Write-Host "Attempting to uninstall Ops Agent..."
    googet -noconfirm remove google-cloud-ops-agent
}

function Uninstall_Package($package) {
    if ($package) {
        Write-Host "Attempting to uninstall: '$package'"
      & $package /S
      Start-Sleep -s 5
      return
    }

    Write-Host "Package not found: '$package'"
}

function Uninstall_StackDriver_Logging() {
    Write-Host "Uninstalling Stackdriver Logging Agent"

    if (Check_Service_Exists StackdriverLogging) {
        Stop-Service -Name StackdriverLogging
    }

    $packageUninstall = "C:\Program Files (x86)\Stackdriver\LoggingAgent\uninstall.exe"
    if ($packageUninstall) {
        Uninstall_Package(packageUninstall)
        return
    }

    $packageUninstall = "C:\dev\stackdriver\LoggingAgent\uninstall.exe"
    if ($packageUninstall) {
        Uninstall_Package(packageUninstall)
        return
    }
}

function Uninstall_StackDriver_Monitoring() {
    Write-Host "Uninstalling Stackdriver Monitoring Agent"

    if (Check_Service_Exists StackdriverMonitoring) {
        Stop-Service -Name StackdriverMonitoring
    }

    $packageUninstall = "C:\Program Files (x86)\Stackdriver\MonitoringAgent\uninstall.exe"
    if ($packageUninstall) {
        Uninstall_Package(packageUninstall)
        return
    }

    $packageUninstall = "C:\dev\stackdriver\monitoringAgent\uninstall.exe"
    if ($packageUninstall) {
        Uninstall_Package(packageUninstall)
        return
    }
}

function Install_StackDriver_Logging($loggingagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_args = "/S /D='C:\dev\stackdriver\loggingAgent'"
    Start-Process -Wait "C:\dev\data\$($loggingagent)" -ArgumentList $logging_args
}

function Install_StackDriver_Monitoring($monitoringagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_args = "/S /D='C:\dev\stackdriver\monitoringAgent'"
    Start-Process -Wait "C:\dev\data\$($monitoringagent)" -ArgumentList $monitoring_args
}

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

if (Check_Service_Exists google-cloud-ops-agent) {
    Uninstall_Ops_Agent
}

Uninstall_StackDriver_Logging
Install_StackDriver_Logging $loggingagent $GCP_BUCKET

Uninstall_StackDriver_Monitoring
Install_StackDriver_Monitoring $monitoringagent $GCP_BUCKET
