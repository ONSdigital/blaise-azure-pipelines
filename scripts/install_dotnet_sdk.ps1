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

if (-not (Test-Path -Path $exePath -PathType Leaf)) {
    throw "Installer not found at '$exePath'. Check ENV_DOT_NET_SDK and ensure the file exists."
}

LogInfo("Installing .NET SDK $requiredVersion...")

$process = Start-Process `
    -FilePath $exePath `
    -ArgumentList "/quiet /norestart" `
    -NoNewWindow `
    -Wait `
    -PassThru

# Code 0 = Success
# Code 3010 = Success (Reboot required)
if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
    throw "Installation failed with exit code $($process.ExitCode)"
}

if ($process.ExitCode -eq 3010) {
    LogInfo(".NET SDK installed successfully, but a system reboot is required.")
}
