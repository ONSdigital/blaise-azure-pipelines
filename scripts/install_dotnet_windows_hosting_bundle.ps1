. "$PSScriptRoot\logging_functions.ps1"

function Get-RequiredHostingBundleVersion {
    if ($env:ENV_DOT_NET_HOSTING_BUNDLE -match '^dotnet-hosting-([0-9]+\.[0-9]+\.[0-9]+)-') {
        return $Matches[1]
    }

    throw "Unable to determine hosting bundle version from '$env:ENV_DOT_NET_HOSTING_BUNDLE'"
}

function Is-DotNetHostingBundleInstalled {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -like "*Microsoft ASP.NET Core*" -and
                $_.DisplayVersion -like "$Version*"
            }

        if ($installed) {
            return $true
        }
    }

    return $false
}

$requiredVersion = Get-RequiredHostingBundleVersion

if (Is-DotNetHostingBundleInstalled -Version $requiredVersion) {
    LogInfo(".NET Hosting Bundle $requiredVersion already installed")
    return
}

$exePath = "C:\dev\data\$env:ENV_DOT_NET_HOSTING_BUNDLE"

LogInfo("Installing .NET Hosting Bundle $requiredVersion...")

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
    LogInfo(".NET Hosting Bundle installed successfully, but a system reboot is required.")
}