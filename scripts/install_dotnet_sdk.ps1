. "$PSScriptRoot\logging_functions.ps1"

function Get-RequiredSdkVersion {
    if ($env:ENV_DOT_NET_SDK -match '^dotnet-sdk-([0-9]+\.[0-9]+\.[0-9]+)-') {
        return $Matches[1]
    }

    throw "Unable to determine SDK version from '$env:ENV_DOT_NET_SDK'"
}

function Test-DotNetSDKInstalled {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $dotnet) {
        return $false
    }

    $installedSdks = & dotnet --list-sdks 2>$null

    return $installedSdks -match "^$([regex]::Escape($Version))\s"
}

$requiredVersion = Get-RequiredSdkVersion

if (Test-DotNetSDKInstalled -Version $requiredVersion) {
    LogInfo(".NET SDK $requiredVersion is already installed")
    return
}

$exePath = "C:\dev\data\$env:ENV_DOT_NET_SDK"

LogInfo("Installing .NET SDK $requiredVersion...")
Start-Process -FilePath $exePath -ArgumentList "/quiet /norestart" -NoNewWindow -Wait

if ($LASTEXITCODE -ne 0) {
    throw "Installation failed with exit code $LASTEXITCODE"
}