# Needed for Blaise versions running dashboard on .NET
# Redirects Blaise self-referential HTTPS calls to localhost

. "$PSScriptRoot\logging_functions.ps1"

# Ensure all errors are terminating
$ErrorActionPreference = "Stop"

if (-not ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.16")) {
    LogInfo("Hosts entry not required for Blaise $env:ENV_BLAISE_CURRENT_VERSION")
    return
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostname = $env:ENV_BLAISE_CATI_URL
$ipAddress = "127.0.0.1"
$entry = "$ipAddress`t$hostname"

try {
    $hostsContent = Get-Content -Path $hostsPath -ErrorAction Stop
    if ($hostsContent -match [regex]::Escape($hostname)) {
        LogInfo("Hosts entry for '$hostname' already exists")
    }
    else {
        LogInfo("Adding hosts entry for '$hostname' -> $ipAddress...")
        Add-Content -Path $hostsPath -Value $entry
        LogInfo("Hosts entry added successfully")
    }
}
    catch {
        LogError("Failed to update hosts file")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
}
