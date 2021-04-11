param ([string]$MonitoringExe, [string]$LoggingExe, [string]$FolderPath)

function DownloadFileIfItDoesntExist {
    param ([string] $FileName, [string]$FolderPath)
    if (!(Test-Path "$FolderPath\$FileName" -PathType Leaf))
    {
    $env:ENV_BLAISE_GCP_BUCKET = "ons-blaise-v2-dev-multi-winvm-data"
    Write-Host "Downloading $FileName..."
    gsutil cp gs://$env:ENV_BLAISE_GCP_BUCKET/$FileName $FolderPath\$FileName
    }
}

function StartServiceIfStopped {
    param (
        [string] $ServiceName
    )
    If ((Get-Service $ServiceName).Status -eq 'Stopped') 
    {
        Start-Service $ServiceName
        Write-Host "Starting $ServiceName"
    }
    Else {
        Write-Host "$ServiceName found and running nothing to do..."
    }
}

New-Item -Path "$FolderPath" -ItemType "directory" -Force

#############
# MONITORING
#############
$monitor_service = "StackdriverMonitoring"

If (Get-Service $monitor_service -ErrorAction SilentlyContinue) 
{
    StartServiceIfStopped -ServiceName $monitor_service
}
Else {
    DownloadFileIfItDoesntExist -FileName:$MonitoringExe -FolderPath $FolderPath
    Start-Sleep -s 10
    Write-Host "Installing Stackdriver monitoring agent..."
    C:\dev\stackdriver\StackdriverMonitoring-GCM-46.exe /S /D="c:\dev\stackdriver\monitoring"
    Write-Host "Installed Stackdriver monitoring agent"
}
