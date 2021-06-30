function Install_OpsAgent {
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1")
    Invoke-Expression "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1 -AlsoInstall"
}

function Check_Service {
    param (
        $Service_Name
    )
    if (Get-Service $Service_Name | Where-Object {$_.Status -eq "Running"}) {
        Write-Host "$Service_Name already started, nothing to do..."
        return $TRUE
    }
    elseif (Get-Service $Service_Name | Where-Object {$_.Status -eq "Stopped"}) {
        Write-Host "Starting service $Service_Name"
        Start-Service -Name $Service_Name
        return $TRUE
    }
    else {
        Write-Host "Error, service $Service_Name not found..."
        return $FALSE
    }
}

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Google Cloud Ops Agent Running"
}
elseif (Check_Service StackdriverMonitoring) {
    Write-Host "Old Stackdriver Monitoring Agent is running please manually uninstall using sc.exe delete StackdriverMonitoring and stop the service then rerun this script"
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
