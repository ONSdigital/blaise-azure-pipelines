. "$PSScriptRoot\logging_functions.ps1"

function Is-DotNetHostingBundleInstalled {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Microsoft ASP.NET Core 8.0.14*" }
        if ($installed) { return $true }
    }
    return $false
}

if (Is-DotNetHostingBundleInstalled) {
    LogInfo("dotnet hosting bundle already installed.")
    return
}

$exePath = "C:\dev\data\dotnet-hosting-8.0.14-win.exe"

if (-not (Test-Path $exePath)) {
    LogInfo("Downloading dotnet hosting bundle...")
    gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/dotnet-hosting-8.0.14-win.exe" $exePath
} else {
    LogInfo("dotnet hosting bundle installer already downloaded.")
}

LogInfo("Installing dotnet hosting bundle...")
Start-Process -FilePath $exePath -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
