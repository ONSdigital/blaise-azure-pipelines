param(
    [Parameter(Mandatory = $true)]
    [string] $GCPPath,

    [Parameter(Mandatory = $true)]
    [string] $SDKMinVersion
)

$minSDKVersion = [Version]$SDKMinVersion
$gcloudExe = Join-Path $GCPPath "gcloud.cmd"
$currentSDKVersion = $null

if (Test-Path $gcloudExe) {
    Write-Host "Found gcloud at expected location: $gcloudExe"
    
    # Set bundled Python path if it exists
    $sdkRoot = Split-Path $GCPPath
    $platformPath = Join-Path $sdkRoot "platform"
    $pythonExe = Join-Path $platformPath "bundledpython\python.exe"
    if (Test-Path $pythonExe) {
        $env:CLOUDSDK_PYTHON = $pythonExe
    }
    
    try {
        $verOutput = & $gcloudExe version --format="value(version)" 2>&1
        if ($verOutput -match "^(\d+\.\d+\.\d+)$") {
            $currentSDKVersion = [Version]$matches[1]
            Write-Host "Detected installed gcloud version: $currentSDKVersion"
        }
        else {
            Write-Host "Unexpected version output: $verOutput"
        }
    }
    catch {
        Write-Host "Failed to check gcloud version: $_"
    }
}
else {
    Write-Host "gcloud not found at: $gcloudExe"
}

if (($null -eq $currentSDKVersion) -or ($currentSDKVersion -lt $minSDKVersion)) {
    Write-Host "Installing Google Cloud SDK..."
    Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile "GoogleCloudSDKInstaller.exe"
    Start-Process -Wait -FilePath ".\GoogleCloudSDKInstaller.exe" -ArgumentList "/S"
    $GCPPath = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin"
    if (Test-Path $GCPPath) {
        Write-Host "##vso[task.setvariable variable=PATH]$env:PATH;$GCPPath"
        Write-Host "Added $GCPPath to PATH"
    }
}
else {
    Write-Host "Skipping gcloud sdk installation, required version already exists... "
}
