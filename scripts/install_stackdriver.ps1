. "$PSScriptRoot\logging_functions.ps1"

param (
    [Parameter(Mandatory=$true)][string]$LoggingAgent,
    [Parameter(Mandatory=$true)][string]$MonitoringAgent,
    [Parameter(Mandatory=$true)][string]$GcpBucket
)

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
        [string]$GcpBucket
    )

    $installerPath = "C:\dev\data\$AgentInstaller"
    $serviceName = "Stackdriver$AgentType"

    try {
        LogInfo("Downloading $AgentType agent installer from $GcpBucket bucket...")
        gsutil cp "gs://$GcpBucket/$AgentInstaller" $installerPath

        LogInfo("Installing $AgentType agent...")
        $installArgs = "/S /D=`"C:\Program Files (x86)\stackdriver\${AgentType}Agent`""
        Start-Process -Wait $installerPath -ArgumentList $installArgs

        if (Test-ServiceExists $serviceName) {
            LogInfo("$AgentType agent installed successfully"
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

    if (Test-ServiceExists 'google-cloud-ops-agent') {
        Uninstall-OpsAgent
    }

    if (-not (Test-ServiceExists 'StackdriverLogging')) {
        Install-StackdriverAgent 'Logging' $LoggingAgent $GcpBucket
    } else {
        LogInfo("Stackdriver logging agent already installed")
    }

    if (-not (Test-ServiceExists 'StackdriverMonitoring')) {
        Install-StackdriverAgent 'Monitoring' $MonitoringAgent $GcpBucket
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
