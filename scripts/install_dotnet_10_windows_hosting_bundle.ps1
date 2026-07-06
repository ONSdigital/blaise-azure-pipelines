. "$PSScriptRoot\logging_functions.ps1"

function Is-DotNetHostingBundleInstalled {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Microsoft ASP.NET Core 10*" }
        if ($installed) { return $true }
    }
    return $false
}

if (Is-DotNetHostingBundleInstalled) { 
    LogInfo(".NET 10 windows hosting bundle already installed")
    return
}

$exePath = "C:\dev\data\dotnet-hosting-10.0.9-win.exe"

if (-not (Test-Path $exePath)) {
    LogInfo("Downloading .NET 10 windows hosting bundle...")
    gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/dotnet-hosting-10.0.9-win.exe" $exePath
} else {
    LogInfo(".NET 10 windows hosting bundle installer already downloaded")
}

LogInfo("Installing .NET 10 windows hosting bundle...")
Start-Process -FilePath $exePath -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
