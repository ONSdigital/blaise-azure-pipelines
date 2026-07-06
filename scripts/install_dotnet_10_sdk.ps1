. "$PSScriptRoot\logging_functions.ps1"

function Is-DotNetSDKInstalled {
    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $dotnet) { return $false }

    if ((& dotnet --list-sdks 2>$null) -match '^10\.') {
        return $true
    }

    return $false
}

if (Is-DotNetSDKInstalled) {
    LogInfo(".NET 10 SDK already installed")
    return
}

$exePath = "C:\dev\data\dotnet-sdk-10.0.301-win-x64.exe"

if (-not (Test-Path $exePath)) {
    LogInfo("Downloading .NET 10 SDK...")
    gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/dotnet-sdk-10.0.301-win-x64.exe" $exePath
} else {
    LogInfo(".NET 10 SDK installer already downloaded")
}

LogInfo("Installing .NET 10 SDK...")
Start-Process -FilePath $exePath -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
