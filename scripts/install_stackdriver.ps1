# to do - change agent version if installed version doesn't match

param (
    [string]$loggingagent,
    [string]$monitoringagent,
    [string]$GCP_BUCKET
)

. "$PSScriptRoot\logging_functions.ps1"

function Start-ServiceIfNotRunning {
    param ([string]$ServiceName)
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne 'Running') {
        Start-Service $ServiceName
    }
}

function Test-ServiceExists {
    param ([string]$ServiceName)
    return $null -ne (Get-Service $ServiceName -ErrorAction SilentlyContinue)
}

function Uninstall-OpsAgent {
    LogInfo("Uninstalling Google ops agent...")
    googet -noconfirm remove google-cloud-ops-agent
}

function Install-StackDriverAgent {
    param (
        [string]$AgentType,
        [string]$AgentFileName,
        [string]$InstallPath
    )
    LogInfo("Downloading Stackdriver $AgentType agent installer from $GCP_BUCKET bucket...")
    $localPath = Join-Path 'C:\dev\data' $AgentFileName
    gsutil cp "gs://$GCP_BUCKET/$AgentFileName" $localPath

    LogInfo("Installing Stackdriver $AgentType agent...")
    $args = "/S /D='$InstallPath'"
    Start-Process -Wait $localPath -ArgumentList $args
}

if (Test-ServiceExists 'google-cloud-ops-agent') {
    Uninstall-OpsAgent
}

if (-not (Test-ServiceExists 'StackdriverLogging')) {
    Install-StackDriverAgent 'logging' $loggingagent 'C:\Program Files (x86)\stackdriver\loggingAgent'
}

if (-not (Test-ServiceExists 'StackdriverMonitoring')) {
    Install-StackDriverAgent 'monitoring' $monitoringagent 'C:\Program Files (x86)\stackdriver\monitoringAgent'
}

Start-ServiceIfNotRunning 'StackdriverLogging'
Start-ServiceIfNotRunning 'StackdriverMonitoring'
