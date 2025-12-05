param(
    [Parameter(Mandatory = $true)]
    [string] $SystemAccessToken,

    [Parameter(Mandatory = $true)]
    [string] $SharedServiceAccount,

    [Parameter(Mandatory = $true)]
    [string] $SharedBucket,

    [Parameter(Mandatory = $true)]
    [string] $FileName,

    [Parameter(Mandatory = $true)]
    [string] $DestinationPath
)

. "$PSScriptRoot\logging_functions.ps1"

function Get-AzureOidcToken {
    $oidcUrl = "$($env:SYSTEM_COLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/distributedtask/hubs/$($env:SYSTEM_HOSTTYPE)/plans/$($env:SYSTEM_PLANID)/jobs/$($env:SYSTEM_JOBID)/oidctoken?api-version=7.2-preview.1"
    
    LogInfo("Requesting OIDC token from Azure DevOps...")
    
    $response = Invoke-RestMethod -Method Post -Uri $oidcUrl -Headers @{
        "Authorization" = "Bearer $SystemAccessToken"
        "Content-Type"  = "application/json"
    }

    if (-not $response.oidcToken) {
        LogError("Could not fetch OIDC token from Azure DevOps")
    }
    
    LogInfo("Azure OIDC Token retrieved successfully!")
    return $response.oidcToken
}

function Reset-GcloudToDefault {
    param([string]$DefaultSA)
    
    LogInfo("Resetting gcloud to VM default service account...")

    # Remove WIF credential files
    $filesToRemove = @(
        (Join-Path $env:TEMP "gcp-wif.json"),
        (Join-Path $env:TEMP "token.jwt"),
        (Join-Path $env:APPDATA "gcloud\application_default_credentials.json")
    )
    
    foreach ($file in $filesToRemove) {
        if (Test-Path $file) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            LogInfo("Removed: $file")
        }
    }

    # Remove GOOGLE_APPLICATION_CREDENTIALS if set
    if ($env:GOOGLE_APPLICATION_CREDENTIALS) {
        Remove-Item Env:GOOGLE_APPLICATION_CREDENTIALS -ErrorAction SilentlyContinue
        LogInfo("Cleared GOOGLE_APPLICATION_CREDENTIALS")
    }

    # Clean gcloud credential store
    $gcloudDir = Join-Path $env:USERPROFILE ".config\gcloud"
    $credPaths = @(
        "$gcloudDir\credentials.db",
        "$gcloudDir\access_tokens.db",
        "$gcloudDir\legacy_credentials"
    )
    foreach ($p in $credPaths) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Ensure default configuration exists and is active
    $hasDefault = gcloud config configurations list --format="value(name)" 2>$null | Select-String -Quiet "default"
    if (-not $hasDefault) {
        gcloud config configurations create default --quiet 2>$null
    }
    gcloud config configurations activate default --quiet 2>$null

    # Set account to VM default if provided
    if ($DefaultSA) {
        gcloud config set account $DefaultSA --quiet 2>$null
        LogInfo("Set active account to: $DefaultSA")
    } else {
        # Unset account to force metadata service usage
        gcloud config unset account --quiet 2>$null
        LogInfo("Unset account config - will use VM metadata service")
    }

    # Verify
    $activeAccount = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
    if ($activeAccount) {
        LogInfo("Active account: $activeAccount")
    } else {
        LogInfo("No explicit active account - using VM metadata service")
    }
}

try {
    LogInfo("Starting GCP authentication with WIF using SA impersonation...")

    # ----------------------------------------------------------
    # 1. Retrieve Azure DevOps OIDC Token
    # ----------------------------------------------------------

    LogInfo("Authenticating with shared service account")

    $oidcToken = Get-AzureOidcToken

    # Prepare locations for ephemeral files
    $wifJson = Join-Path $env:TEMP "gcp-wif.json"
    $tokenFile = Join-Path $env:TEMP "token.jwt"

    # Write Azure token to disk
    Set-Content -Path $tokenFile -Value $oidcToken

    # ----------------------------------------------------------
    # 2. Build WIF Config JSON
    # ----------------------------------------------------------

    $audience = "//iam.googleapis.com/projects/2727969180/locations/global/workloadIdentityPools/azure-devops-identity-pool/providers/azure-wif-auth-provider"
    $impersonationUrl = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${SharedServiceAccount}:generateAccessToken"

    $wifConfig = @{
        type                              = 'external_account'
        audience                          = $audience
        subject_token_type                = 'urn:ietf:params:oauth:token-type:jwt'
        token_url                         = 'https://sts.googleapis.com/v1/token'
        service_account_impersonation_url = $impersonationUrl
        credential_source                 = @{ file = $tokenFile }
    }

    $wifConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $wifJson -Encoding UTF8

    LogInfo("Logging in with WIF credential file...")
    & gcloud auth login --cred-file=$wifJson --quiet

    # ----------------------------------------------------------
    # 3. Download File from Shared Bucket
    # ----------------------------------------------------------

    LogInfo("Downloading $FileName...")
    LogInfo("Source: gs://$SharedBucket/$FileName")
    LogInfo("Destination: $DestinationPath")

    & gcloud storage cp "gs://$SharedBucket/$FileName" $DestinationPath

    if ($LASTEXITCODE -ne 0) {
        throw "Download failed with exit code $LASTEXITCODE"
    }

    LogInfo("File downloaded successfully!")
}
catch {
    LogError("ERROR during file download: $_")
    exit 1
}
finally {
    # ----------------------------------------------------------
    # Cleanup / Reset active account to VM default
    # ----------------------------------------------------------
    Reset-GcloudToDefault
    LogInfo("Cleanup complete.")
}
