function Install_StackDriver() {
    Write-Host "This is a function to install StackDriver"
}

function Uninstall_OpsAgent() {
    Write-Host "Uninstalling Ops Agent"
    googet -noconfirm remove google-cloud-ops-agent
}

function Check_Service($Service_Name) {
    if (Get-Service $Service_Name -ErrorAction SilentlyContinue) {
        if (Get-Service $Service_Name | Where-Object {$_.Status -eq "Running"}) {
            Write-Host "$Service_Name already started, nothing to do..."
            return $TRUE
        }
        else {
            Write-Host "Starting service $Service_Name"
            Start-Service -Name $Service_Name
            return $TRUE
        }
    }
    else {
        Write-Host "Service $Service_Name not found, continuing..."
        return $FALSE
    }
}

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Google Cloud Ops Agent running, uninstalling and installing Ops Agent"
    Uninstall_OpsAgent
} else {
    Write-Host "No evidence of agents found, installing Stackdriver Logging and Monitoring"
    Install_StackDriver
}

exit 0