function Check_Service($Service_Name) {
    if (Get-Service $Service_Name -ErrorAction SilentlyContinue) {
        if (Get-Service $Service_Name | Where-Object {$_.Status -eq "Running"}) {
            Write-Host "$Service_Name already started, nothing to do..."
            return $TRUE
        }
        else {
            Write-Host "$Service_Name found and running..."
            return $True
        }
    }
    else {
        Write-Host "Service $Service_Name not found, continuing..."
        return $FALSE
    }
}

if (Check_Service google-cloud-ops-agent) {
    Write-Host "Google Cloud Ops agent running, executing update..."
    googet -noconfirm remove google-cloud-ops-agent
    googet -noconfirm install google-cloud-ops-agent
}
elseif (Check_Service StackdriverMonitoring) {
    Write-Host "Old Stackdriver Monitoring agent is running, uninstalling and installing Ops Agent"
    Stop-Service -Name StackdriverMonitoring
    sc.exe delete StackdriverMonitoring
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1")
    $ErrorActionPreference = "Continue"
    & "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1" -AlsoInstall -UninstallStandaloneLoggingAgent
}
elseif (Check_Service StackdriverLogging) {
    Write-Host "Old Stackdriver Logging agent is running, uninstalling and installing Ops Agent"
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1")
    $ErrorActionPreference = "Continue"
    & "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1" -AlsoInstall -UninstallStandaloneLoggingAgent
}
else {
    Write-Host "No evidence of agents found, installing ops agent"
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1")
    $ErrorActionPreference = "Continue"
    & "$PSScriptRoot\add-google-cloud-ops-agent-repo.ps1" -AlsoInstall
}

Write-Host "Agent Installation Completed"

exit 0
