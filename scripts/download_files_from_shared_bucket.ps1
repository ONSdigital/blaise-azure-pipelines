param(
    [Parameter(Mandatory = $true)]
    [string] $SystemAccessToken,

    [Parameter(Mandatory = $true)]
    [string] $SharedServiceAccount,

    [Parameter(Mandatory = $true)]
    [string] $SharedBucket,

    [Parameter(Mandatory = $true)]
    [string[]] $FileName,

    [Parameter(Mandatory = $true)]
    [string[]] $DestinationPath   
)

. "$PSScriptRoot\functions\logging_functions.ps1"

if ($FileName.Count -ne $DestinationPath.Count) {
    LogError("The number of filenames and destination paths must match.")
    exit 1
}

function Get-AzureOidcToken {
    $oidcUrl = "$($env:SYSTEM_COLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/distributedtask/hubs/$($env:SYSTEM_HOSTTYPE)/plans/$($env:SYSTEM_PLANID)/jobs/$($env:SYSTEM_JOBID)/oidctoken?api-version=7.2-preview.1"
    
    LogInfo("Requesting OIDC token from Azure DevOps...")
    
    $response = Invoke-RestMethod -Method Post -Uri $oidcUrl -Headers @{
        "Authorization" = "Bearer $SystemAccessToken"
        "Content-Type"  = "application/json"
    }

    if (-not $response.oidcToken) {
        LogError("Could not fetch OIDC token from Azure DevOps")
        throw "Could not fetch OIDC token from Azure DevOps"
    }
    
    LogInfo("Azure OIDC Token retrieved successfully!")
    return $response.oidcToken
}

try {
    LogInfo("Starting GCP authentication with WIF using SA impersonation...")
    LogInfo("Authenticating with shared service account: $SharedServiceAccount")

    $oidcToken = Get-AzureOidcToken

    # Prepare locations for ephemeral files
    $wifJson = Join-Path $env:TEMP "gcp-wif.json"
    $tokenFile = Join-Path $env:TEMP "token.jwt"

    # Write Azure token to disk
    Set-Content -Path $tokenFile -Value $oidcToken

    # Build WIF Config JSON
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

    for ($i = 0; $i -lt $FileName.Count; $i++) {
        
        $file = $FileName[$i]
        $dest = $DestinationPath[$i]

        LogInfo("Downloading $file...")
        LogInfo("Source: gs://$SharedBucket/$file")
        LogInfo("Destination: $dest")

        & gcloud storage cp "gs://$SharedBucket/$file" $dest
        
        if ($LASTEXITCODE -ne 0) {
            throw "Download failed with exit code $LASTEXITCODE"
        }
        
    }

    LogInfo("File downloaded successfully!")
}
catch {
    LogError("ERROR during file download: $_")
    exit 1
}
finally {
    & "$PSScriptRoot\reset_gcloud_account.ps1"
}