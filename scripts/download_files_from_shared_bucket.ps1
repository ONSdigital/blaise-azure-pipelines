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

try {
    Write-Host "[INFO] Starting GCP authentication with WIF using SA impersonation..."

    # ----------------------------------------------------------
    # 1. Retrieve Azure DevOps OIDC Token
    # ----------------------------------------------------------

    Write-Host "[AUTH] Authenticating with service account $SharedServiceAccount"

    $oidcUrl = "$($env:SYSTEM_COLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/distributedtask/hubs/$($env:SYSTEM_HOSTTYPE)/plans/$($env:SYSTEM_PLANID)/jobs/$($env:SYSTEM_JOBID)/oidctoken?api-version=7.2-preview.1"
    Write-Host "[INFO] Requesting OIDC token from Azure DevOps..."

    $response = Invoke-RestMethod -Method Post `
        -Uri $oidcUrl `
        -Headers @{
            "Authorization" = "Bearer $SystemAccessToken"
            "Content-Type"  = "application/json"
        }

    $oidcToken = $response.oidcToken
    Write-Host "[OK] Azure OIDC Token retrieved successfully!"

    if (-not $oidcToken) {
        Write-Error "[ERROR] Could not fetch OIDC token"
        exit 1
    }

    # Prepare locations for ephemeral files
    $wifJson = Join-Path $env:TEMP "gcp-wif.json"
    $tokenFile = Join-Path $env:TEMP "token.jwt"

    # Write Azure token to disk
    Set-Content -Path $tokenFile -Value $oidcToken

    # ----------------------------------------------------------
    # 2. Build WIF Config JSON
    # ----------------------------------------------------------

    $audience = "//iam.googleapis.com/projects/2727969180/locations/global/workloadIdentityPools/azure-devops-identity-pool/providers/azure-wif-auth-provider"
    $impersonationUrl = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$SharedServiceAccount:generateAccessToken"

    $wifConfig = @{
        type                              = "external_account"
        audience                          = $audience
        subject_token_type                = "urn:ietf:params:oauth:token-type:jwt"
        token_url                         = "https://sts.googleapis.com/v1/token"
        service_account_impersonation_url = $impersonationUrl
        credential_source                 = @{
            file = $tokenFile
        }
    }

    $wifConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $wifJson -Encoding UTF8

    Write-Host "[AUTH] Logging in with WIF credential file..."
    gcloud auth login --cred-file=$wifJson --quiet

    Write-Host "[INFO] Impersonating service account for token..."
    gcloud auth print-identity-token --impersonate-service-account=$SharedServiceAccount --quiet

    # ----------------------------------------------------------
    # 3. Download CMA Package
    # ----------------------------------------------------------

    Write-Host "[INFO] Downloading $FileName..."
    Write-Host "[INFO] Source: gs://$SharedBucket/$FileName"
    Write-Host "[INFO] Destination: $DestinationPath"

    gcloud storage cp "gs://$SharedBucket/$FileName" $DestinationPath

    Write-Host "[OK] $FileName downloaded successfully!"
}
catch {
    Write-Host "[ERROR] ERROR during $FileName download!"
    Write-Error "[ERROR] Exception details: $_"
    exit 1
}
finally {
    # ----------------------------------------------------------
    # Cleanup / Reset gcloud
    # ----------------------------------------------------------

    Write-Host "[AUTH] Revoking service account impersonation: $SharedServiceAccount"
    gcloud auth revoke $SharedServiceAccount --quiet 2>$null

    Write-Host "[CLEANUP] Cleaning residual credential files..."

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
        Write-Host "[CLEANUP] Cleaning GOOGLE_APPLICATION_CREDENTIALS override..."
        Remove-Item Env:GOOGLE_APPLICATION_CREDENTIALS -ErrorAction SilentlyContinue
    }

    Write-Host "[CONFIG] Ensuring 'default' gcloud config exists..."
    if (-not (gcloud config configurations list --format="value(name)" | Select-String -Quiet "default")) {
        gcloud config configurations create default --quiet
    }

    Write-Host "[CONFIG] Activating default configuration..."
    gcloud config configurations activate default --quiet

    Write-Host "[INFO] Validating access token (should come from metadata)..."
    $active = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
    Write-Host "Active account: $active"

    $token = gcloud auth print-access-token 2>$null
    if ($LASTEXITCODE -eq 0 -and $token.Length -gt 100) {
        Write-Host "[OK] VM now using metadata service account"
    } else {
        Write-Host "[ERROR] Token retrieval failed - metadata SA not active"
    }

    Write-Host "[DONE] Cleanup complete."
}
