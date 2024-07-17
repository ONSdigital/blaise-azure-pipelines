# to do - change agent version if installed version doesn't match

. "$PSScriptRoot\logging_functions.ps1"

function Start-ServiceIfNotRunning {
    param([string]$ServiceName)
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne 'Running') {
        Start-Service $service
        LogInfo("Started service: $ServiceName")
    }
}

function Test-ServiceExists {
    param([string]$ServiceName)
    return [bool](Get-Service $ServiceName -ErrorAction SilentlyContinue)
}

function Uninstall-OpsAgent {
    LogInfo("Uninstalling Google ops agent...")
    try {
        googet -noconfirm remove google-cloud-ops-agent
        LogInfo("Google ops agent uninstalled successfully")
    }
    catch {
        LogError("Error uninstalling Google ops agent: $_")
    }
}

function Uninstall-StackdriverLogging {
    if (Test-ServiceExists 'StackdriverLogging') {
        LogInfo("Stopping StackdriverLogging service")
        Stop-Service -Name StackdriverLogging -ErrorAction Stop
    }
}

function Install-StackdriverAgent {
    param(
        [string]$AgentType,
        [string]$AgentInstaller,
        [string]$GCP_BUCKET
    )
    $installerPath = "C:\dev\data\$AgentInstaller"
    $serviceName = "Stackdriver$AgentType"
    try {
        LogInfo("Downloading $AgentType agent installer from $GCP_BUCKET bucket...")
        $gsutilOutput = gsutil cp "gs://$GCP_BUCKET/$AgentInstaller" $installerPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "gsutil command failed: $gsutilOutput"
        }
        
        if (!(Test-Path $installerPath)) {
            throw "Installer not found at $installerPath after download attempt"
        }

        LogInfo("Installing $AgentType agent...")
        $installArgs = "/S /D=`"C:\Program Files (x86)\stackdriver\${AgentType}Agent`""
        $processInfo = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
        if ($processInfo.ExitCode -ne 0) {
            throw "Installation process exited with code $($processInfo.ExitCode)"
        }

        if (Test-ServiceExists $serviceName) {
            LogInfo("$AgentType agent installed successfully")
            Remove-Item $installerPath -Force
        } else {
            throw "Service $serviceName not found after installation"
        }
    }
    catch {
        LogError("Error installing $AgentType agent: $_")
        throw
    }
}

try {
    LogInfo("Starting Stackdriver agent install...")

    param ([string]$LoggingAgent, [string]$MonitoringAgent, [string]$GCP_BUCKET)
    
    if ([string]::IsNullOrEmpty($LoggingAgent) -or [string]::IsNullOrEmpty($MonitoringAgent) -or [string]::IsNullOrEmpty($GCP_BUCKET)) {
        throw "One or more required parameters are missing. Please ensure LoggingAgent, MonitoringAgent, and GCP_BUCKET are provided."
    }

    if (Test-ServiceExists 'google-cloud-ops-agent') {
        Uninstall-OpsAgent
    }

    if (-not (Test-ServiceExists 'StackdriverLogging')) {
        Install-StackdriverAgent 'Logging' $LoggingAgent $GCP_BUCKET
    } else {
        LogInfo("Stackdriver logging agent already installed")
    }

    if (-not (Test-ServiceExists 'StackdriverMonitoring')) {
        Install-StackdriverAgent 'Monitoring' $MonitoringAgent $GCP_BUCKET
    } else {
        LogInfo("Stackdriver monitoring agent already installed")
    }

    LogInfo("Stackdriver agent install completed successfully")
    exit 0
}
catch {
    LogError("Error during Stackdriver agent install: $_")
    exit 1
}
