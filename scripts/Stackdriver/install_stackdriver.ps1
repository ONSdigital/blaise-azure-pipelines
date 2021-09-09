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

function Install_StackDriver_Monitoring($monitoringagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver monitoring agent installer from '$($GCP_BUCKET)'..."
    gsutil cp gs://$GCP_BUCKET/$monitoringagent "C:\dev\data\$($monitoringagent)"

    Write-Host "Installing Stackdriver monitoring agent..."
    $monitoring_args = "/S /D='C:\dev\stackdriver\monitoringAgent'"
    Start-Process -Wait "C:\dev\data\$($monitoringagent)" -ArgumentList $monitoring_args
}

function Install_StackDriver_Logging($loggingagent, $GCP_BUCKET) {
    Write-Host "Downloading Stackdriver logging agent installer from '$GCP_BUCKET'..."
    gsutil cp gs://$GCP_BUCKET/$loggingagent "C:\dev\data\$($loggingagent)"

    Write-Host "Installing Stackdriver logging agent..."
    $logging_args = "/S /D='C:\dev\stackdriver\loggingAgent'"
    Start-Process -Wait "C:\dev\data\$($loggingagent)" -ArgumentList $logging_args
}

function Uninstall-StackdriverLogging() {
    Write-Host "Uninstalling Stackdriver Logging Agent"
    $packageUninstall = Get-ItemPropertyValue 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\GoogleStackdriverLoggingAgent' -Name UninstallString
    if ($packageUninstall) {
      & $packageUninstall /S
      Start-Sleep -s 5
    }
}

function Uninstall-StackdriverMonitoring() {
    Write-Host "Uninstalling Stackdriver Monitoring Agent"
        Stop-Service -Name StackdriverMonitoring
        sc.exe delete StackdriverMonitoring
}

function Uninstall-Ops-Agent() {
    Write-Host "Attempting to uninstall Ops Agent..."
    googet -noconfirm remove google-cloud-ops-agent
}

Write-Host "Target logging agent is: $($loggingagent)"
Write-Host "Target monitoring agent is: $($monitoringagent)"
Write-Host "GCP artifact bucket is: $($GCP_BUCKET)"

if (Check_Service google-cloud-ops-agent) {
    Uninstall-Ops-Agent
}

if (Check_Service StackdriverMonitoring) {
    Uninstall-StackdriverMonitoring
}

if (Check_Service StackdriverLogging) {
    Uninstall-StackdriverLogging
}

Write-Host "Attempting to install Stackdriver agents"
Install_StackDriver_Monitoring $monitoringagent $GCP_BUCKET
Install_StackDriver_Logging $loggingagent, $GCP_BUCKET
