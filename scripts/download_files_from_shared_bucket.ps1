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

# function CheckDefaultServiceAccountActivation {
#     LogInfo("Validating access token, should come from metadata...")
#     $active = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
#     LogInfo("Active account: $active")
#     $token = gcloud auth print-access-token 2>$null
#     if ($LASTEXITCODE -eq 0 -and $token.Length -gt 100) {
#         LogInfo("VM now using metadata service account")
#     } else {
#         LogInfo("Token retrieval failed metadata SA not active")
#     }
# }

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
    $impersonationUrl = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/'$SharedServiceAccount':generateAccessToken"

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
    gcloud auth login --cred-file=$wifJson --quiet

    LogInfo("Impersonating service account for token...")
    gcloud auth print-identity-token --impersonate-service-account=$SharedServiceAccount --quiet

    # ----------------------------------------------------------
    # 3. Download CMA Package
    # ----------------------------------------------------------

    LogInfo("Downloading $FileName...")
    LogInfo("Source: gs://$SharedBucket/$FileName")
    LogInfo("Destination: $DestinationPath")

    gcloud storage cp "gs://$SharedBucket/$FileName" $DestinationPath

    LogInfo("File downloaded successfully!")
}

catch {
    LogInfo("ERROR during file download!")
    # Write-Error "Exception details: $_"
    exit 1
}

finally {
    # ----------------------------------------------------------
    # Cleanup / Reset gcloud
    # ----------------------------------------------------------

    LogInfo("Revoking shared service account impersonation")

    gcloud auth revoke $SharedServiceAccount --quiet 2>$null

    LogInfo("Cleaning residual credential files...")

    $gcloudDir = Join-Path $env:USERPROFILE ".config\gcloud"
    $paths = @(
        "$gcloudDir\credentials.db",
        "$gcloudDir\application_default_credentials.json",
        "$gcloudDir\configurations\*.tmp",
        "$gcloudDir\legacy_credentials"
    )

    foreach ($p in $paths) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($env:GOOGLE_APPLICATION_CREDENTIALS) {
        LogInfo("Cleaning GOOGLE_APPLICATION_CREDENTIALS override...")
        Remove-Item Env:GOOGLE_APPLICATION_CREDENTIALS -ErrorAction SilentlyContinue
    }

    LogInfo("Ensuring default gcloud config exists...")
    if (-not (gcloud config configurations list --format="value(name)" | Select-String -Quiet "default")) {
        gcloud config configurations create default --quiet
    }

    LogInfo("Activating default configuration...")
    gcloud config configurations activate default --quiet

    LogInfo("Cleanup complete.")
}
