param(
    [Parameter(Mandatory = $true)]
    [string] $GCPPath,

    [Parameter(Mandatory = $true)]
    [string] $SDKMinVersion
)

# Minimum required version
$minVersion = [Version]"$SDKMinVersion"

# Expected path of gcloud binary
$gcloudExe = Join-Path $GCPPath "gcloud.cmd"
$pythonExe = Join-Path $GCPPath "platform\bundledpython\python.exe"

if (Test-Path $gcloudExe) {
Write-Host "Found gcloud at expected location: $gcloudExe"
    # Ensure gcloud can find Python
    $env:CLOUDSDK_PYTHON = $pythonExe
    try {
        $verOutput = & gcloud --version 2>$null
        if ($verOutput -match "Google Cloud SDK (\d+\.\d+\.\d+)") {
            $currentVersion = [Version]$matches[1]
            Write-Host "Detected installed gcloud version: $currentVersion"
        }
        else{
        Write-Host "Output: $verOutput"
        }
    }
    catch {
        Write-Host "Failed to check gcloud version. Will reinstall."
    }
}
else {
    Write-Host "gcloud not found in expected location."
}

if (($currentVersion -eq $null) -or ($currentVersion -lt $minVersion)) {
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
