<#
.SYNOPSIS
    Resets gcloud to use the VM's default service account.

.DESCRIPTION
    Cleans up WIF credential files, removes temporary tokens, and resets
    gcloud configuration to use the VM's default service account.

.PARAMETER DefaultServiceAccount
    Optional. The default service account to set as active.
    If not provided, gcloud will use the VM metadata service.
#>
param(
    [Parameter(Mandatory = $false)]
    [string] $DefaultServiceAccount = ""
)

. "$PSScriptRoot\logging_functions.ps1"

$ErrorActionPreference = "SilentlyContinue"

LogInfo("Resetting gcloud to VM default service account...")

# Remove GOOGLE_APPLICATION_CREDENTIALS if set
if (Test-Path Env:\GOOGLE_APPLICATION_CREDENTIALS) {
    Remove-Item Env:\GOOGLE_APPLICATION_CREDENTIALS
    LogInfo("Removed GOOGLE_APPLICATION_CREDENTIALS environment variable")
}

# Remove WIF/temp credential files
$filesToRemove = @(
    (Join-Path $env:TEMP "gcp-wif.json"),
    (Join-Path $env:TEMP "token.jwt")
)
if ($env:APPDATA) {
    $filesToRemove += Join-Path $env:APPDATA "gcloud\application_default_credentials.json"
}

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        LogInfo("Removed: $file")
    }
}

# Ensure default configuration is active
$null = & gcloud config configurations activate default --quiet

# Set or unset the account
if ($DefaultServiceAccount) {
    # Revoke non-default service accounts
    LogInfo("Revoking non-default service account credentials...")
    $accounts = & gcloud auth list --format="value(account)" 2>&1 | 
        Where-Object { $_ -notmatch "^(WARNING|ERROR):" } |
        ForEach-Object { $_.Trim().Trim("'") } |
        Select-Object -Unique

    foreach ($account in $accounts) {
        if (-not $account) { continue }
        if ($account -eq $DefaultServiceAccount) {
            LogInfo("  Keeping VM default: $account")
        } elseif ($account -match "\.gserviceaccount\.com$" -and $account -ne $DefaultServiceAccount) {
            LogInfo("  Revoking: $account")
            $null = & gcloud auth revoke $account --quiet 2>&1
        } else {
            LogInfo("  Skipping: $account")
        }
    }

    $null = & gcloud config set account $DefaultServiceAccount --quiet 2>&1
    LogInfo("Set active account to: $DefaultServiceAccount")
} else {
    $null = & gcloud config unset account --quiet 2>&$null
    LogInfo("Unset account config - will use VM metadata service")
}

# Verify current state
$activeAccount = & gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>&1 | 
    Where-Object { $_ -notmatch "^(WARNING|ERROR|Unset):" -and $_ -match "@" }

if ($activeAccount) {
    LogInfo("Active account: $activeAccount")
} else {
    LogInfo("No explicit active account - using VM metadata service")
}

LogInfo("gcloud reset complete")