function Check-ServiceExists {
    param (
        [string]$ServiceName
    )
    try {
        Get-Service -Name $ServiceName -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Check-ProgramExists {
    param (
        [string]$ProgramName
    )
    $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($key in $uninstallKey) {
        if (Get-ItemProperty $key\* | Where-Object { $_.DisplayName -like "*$ProgramName*" }) {
            return $true
        }
    }
    return $false
}

function Check-StackdriverLogging {
    $stackdriverLoggingIsInstalled = Check-ServiceExists "StackdriverLogging" -or Check-ProgramExists "Stackdriver Logging Agent"

    if ($stackdriverLoggingIsInstalled) {
        Write-Output "Stackdriver Logging is installed. Uninstalling it..."
        $loggingAgentUninstallPath = "C:\Program Files (x86)\Stackdriver\LoggingAgent\uninstall.exe"
        if (Test-Path $loggingAgentUninstallPath) {
            Write-Host "Uninstalling Stackdriver Logging Agent..."
            Start-Process -FilePath $loggingAgentUninstallPath -ArgumentList "/S" -Wait
        } else {
            Write-Error "Error: Stackdriver Logging Agent not uninstalled. Please jump on the box, execute C:\Program Files (x86)\Stackdriver\LoggingAgent\uninstall.exe, and restart the VM."
            exit 1
        }
    } else {
        Write-Output "Stackdriver Logging is not installed."
    }
}

function Check-StackdriverMonitoring {
    $stackdriverMonitoringIsInstalled = Check-ServiceExists "StackdriverMonitoring" -or Check-ProgramExists "Stackdriver Monitoring Agent"

    if ($stackdriverMonitoringIsInstalled) {
        Write-Output "Stackdriver Monitoring is installed. Uninstalling it..."
        $monitoringAgentUninstallPath = "C:\Program Files (x86)\Stackdriver\MonitoringAgent\uninstall.exe"
        if (Test-Path $monitoringAgentUninstallPath) {
            Write-Host "Uninstalling Stackdriver Monitoring Agent..."
            Start-Process -FilePath $monitoringAgentUninstallPath -ArgumentList "/S" -Wait
        } else {
            Write-Host "Error: Stackdriver Monitoring Agent not uninstalled. Please jump on the box, execute C:\Program Files (x86)\Stackdriver\MonitoringAgent\uninstall.exe, and restart the VM"
        }
    } else {
        Write-Output "Stackdriver Monitoring is not installed."
    }
}

function Install-GoogleOpsAgent {
    Write-Host "Downloading GCP Cloud Ops Agent..."

    $serviceAccountRoles = gcloud projects get-iam-policy ons-blaise-v2-dev-el47
    Write-Host "DEBUG: serviceAccountRoles: $serviceAccountRoles"
    Write-Host "DEBUG: {env:UserProfile}: ${env:UserProfile}"
    Write-Host "DEBUG: env:UserProfile: $env:UserProfile"

    try {
        Write-Host "DEBUG: Testing Network Connectivity"
        Test-NetConnection -ComputerName "dl.google.com" -Port 443
    } catch {
        Write-Error "DEBUG: Failed to test Network Connectivity. Error: $_"
        return
    }

    try {
        (New-Object Net.WebClient).DownloadFile(
            "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1",
            "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1"
        )
        Write-Host "Download completed successfully."
    } catch {
        Write-Error "Failed to download the installation script. Error: $_"
        return
    }

    try {
        Write-Host "DEBUG: Testing ${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1..."
        Test-Path "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1"
    } catch {
        Write-Error "DEBUG: Failed to test ${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1. Error: $_"
        return
    }

    Write-Host "DEBUG: Checking GCP Cloud Ops Agent..."
    $opsAgentServiceExists = Check-ServiceExists "google-cloud-ops-agent"
    $opsAgentProgramExists = Check-ProgramExists "GooGet - google-cloud-ops-agent"

    Write-Host "Running GCP Cloud Ops Agent..."
    try {
        Invoke-Expression "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1 -AlsoInstall"
        Write-Host "Google Ops Agent installed successfully."
    } catch {
        Write-Error "Failed to run the installation script. Error: $_"
        Get-Content "${env:UserProfile}\add-google-cloud-ops-agent-repo.ps1" -Tail 20
    }
}

function Check-GoogleOpsAgent {
    try {
        $service = Get-Service -Name "google-cloud-ops-agent" -ErrorAction Stop

        if ($service.Status -eq "Stopped") {
            Write-Host "The 'google-cloud-ops-agent' service is stopped. Attempting to start the service..."
            try {
                Start-Service -Name "google-cloud-ops-agent" -ErrorAction Stop
                Write-Host "The 'google-cloud-ops-agent' service has been started successfully."
                return $true
            } catch {
                Write-Error "Failed to start the 'google-cloud-ops-agent' service: $_"
                return $false
            }
        } else {
            Write-Host "The 'google-cloud-ops-agent' service status is: $($service.Status)"
            return $true
        }
    } catch {
        Write-Error "The service 'google-cloud-ops-agent' could not be found. Please ensure it is installed."
        return $false
    }
}

$activeServiceAccount = & gcloud auth list --filter=status:ACTIVE --format="value(account)"
Write-Host "The current active service account is: $activeServiceAccount"

Write-Host "Checking Stackdriver is not installed..."
Check-StackdriverLogging
Check-StackdriverMonitoring

Write-Host "Checking GCP Cloud Ops Agent..."
$opsAgentServiceExists = Check-ServiceExists "google-cloud-ops-agent"
$opsAgentProgramExists = Check-ProgramExists "GooGet - google-cloud-ops-agent"

if (-not ($opsAgentServiceExists -or $opsAgentProgramExists)) {
    Write-Host "Installing Google Ops Agent..."
    Install-GoogleOpsAgent
}

$opsAgentProgramExists = Check-ProgramExists "GooGet - google-cloud-ops-agent"

if (Check-GoogleOpsAgent -and $opsAgentProgramExists) {
    Write-Host "Google Ops Agent is installed and running successfully"
}
