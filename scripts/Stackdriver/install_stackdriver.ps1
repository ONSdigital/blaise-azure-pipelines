function Install_StackDriver_Logging() {
    curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
    sudo bash install-logging-agent.sh

    Write-Host "Sanity checking Stackdriver Logging is a recognised service and has been installed..."
    if (Check_Service StackdriverLogging) {
        Write-Host "Stackdriver Logging Agent is running"
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