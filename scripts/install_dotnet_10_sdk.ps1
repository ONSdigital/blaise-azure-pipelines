. "$PSScriptRoot\logging_functions.ps1"

function Is-DotNetHostingBundleInstalled {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Microsoft .NET AppHost*" }
        if ($installed) { return $true }
    }
    return $false
}

if (Is-DotNetHostingBundleInstalled) {
    LogInfo(".NET 10 SDK already installed")
    return
}

$exePath = "C:\dev\data\dotnet-sdk-10.0.301-win-x86.exe"

if (-not (Test-Path $exePath)) {
    LogInfo("Downloading .NET 10 SDK...")
    gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/dotnet-sdk-10.0.301-win-x86.exe" $exePath
} else {
    LogInfo(".NET 10 SDK installer already downloaded")
}

LogInfo("Installing .NET 10 SDK...")
Start-Process -FilePath $exePath -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
