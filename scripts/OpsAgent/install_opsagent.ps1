function Install_OpsAgent {
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1")
    Invoke-Expression "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1 -AlsoInstall"
}

function Upgrade_OpsAgent {
    Write-Host "Removing old ops agent"
    googet -noconfirm remove google-cloud-ops-agent
    Write-Host "Installing new ops agent"
    googet -noconfirm install google-cloud-ops-agent
}

function Check_Service {
    param (
        $Service_Name
    )
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
        Write-Host "Error, service $Service_Name not found..."
        return $FALSE
    }
}

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Google Cloud Ops Agent Running, Checking to see if it requires and update"
    Upgrade_OpsAgent
}
elseif (Check_Service StackdriverMonitoring) {
    Write-Host "Old Stackdriver Monitoring Agent is running please manually uninstall using sc.exe delete StackdriverMonitoring and stop the service, you may also need to install the logging agent"
    Write-Host "Once the old stackdriver agents are install rerun this script"
    exit 1
}
elseif (Check_Service StackdriverLogging) {
    Write-Host "Old Stackdriver Logging Agent is running please manually uninstall using add/remove programs then rerun this script"
    exit 1
}
else {
    Write-Host "No evidence of agents found, installing ops agent"
    Install_OpsAgent
}

Write-Host "Agent Installation Completed"

exit 0
