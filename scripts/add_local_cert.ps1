# Needed for Blaise versions running dashboard on .NET
# Allows redirected Blaise self-referential HTTPS calls to localhost to be trusted

. "$PSScriptRoot\logging_functions.ps1"

# Ensure all errors are terminating
$ErrorActionPreference = "Stop"

if (-not ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.16")) {
    LogInfo("Local cert not required for Blaise $env:ENV_BLAISE_CURRENT_VERSION")
    return
}

if (-not $env:ENV_BLAISE_CATI_URL) {
    LogError("CATI URL not set - cannot create cert")
    exit 1
}

# Create self-signed cert if it doesn't already exist
$subject = "CN=$env:ENV_BLAISE_CATI_URL"
$existingCert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object { $_.Subject -eq $subject }
if (-not $existingCert) {
    try {
        LogInfo("Creating new self-signed cert for $env:ENV_BLAISE_CATI_URL...")

        $cert = New-SelfSignedCertificate `
            -DnsName $env:ENV_BLAISE_CATI_URL `
            -CertStoreLocation "cert:\LocalMachine\My" `
            -KeyUsage DigitalSignature, KeyEncipherment `
            -FriendlyName "local cert" `
            -NotAfter (Get-Date).AddYears(100)

        LogInfo("Cert created: $($cert.Thumbprint)")
    }
    catch {
        LogError("Failed to create self-signed cert")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}
else {
    LogInfo("Cert already exists: $($existingCert.Thumbprint)")
    $cert = $existingCert
}

# Trust the cert if not already trusted
$trusted = Get-ChildItem -Path cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $trusted) {
    try {
        LogInfo("Adding cert to trusted root store...")
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        $store.Open("ReadWrite")
        $store.Add($cert)
        $store.Close()
    }
    catch {
        LogError("Failed to add cert to trusted root store")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}
else {
    LogInfo("Cert already trusted")
}

# Add SSL binding if not already present
$bindings = netsh http show sslcert | Out-String
$thumbprint = $cert.Thumbprint -replace ' ', ''
try {
    if ($bindings -match "0\.0\.0\.0:443" -and $bindings -match $thumbprint) {
        LogInfo("SSL binding already exists for 0.0.0.0:443")
    } else {
        LogInfo("Creating SSL binding for 0.0.0.0:443...")
        netsh http add sslcert ipport=0.0.0.0:443 certhash=$thumbprint appid='{00112233-4455-6677-8899-AABBCCDDEEFF}'
        if ($LASTEXITCODE -ne 0) { throw "netsh command failed" }
        LogInfo("SSL binding created for 0.0.0.0:443")
    }
}
catch {
    LogError("Failed to create SSL binding for 0.0.0.0:443")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}

# Add hostname binding if not already present
$siteName = "Default Web Site"
$expectedBinding = "*:443:" + $env:ENV_BLAISE_CATI_URL
$existingBinding = Get-WebBinding -Name $siteName | Where-Object { $_.bindingInformation -eq $expectedBinding }
try {
    if ($existingBinding) {
        LogInfo("Hostname SSL binding already exists for ${env:ENV_BLAISE_CATI_URL}:443")
    } else {
        LogInfo("Creating SSL binding for ${env:ENV_BLAISE_CATI_URL}:443...")
        New-WebBinding -Name $siteName -Protocol https -Port 443 -HostHeader $env:ENV_BLAISE_CATI_URL
        LogInfo("Hostname SSL binding created for ${env:ENV_BLAISE_CATI_URL}:443")
    }
}
catch {
    LogError("Failed to create hostname SSL binding for ${env:ENV_BLAISE_CATI_URL}:443")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}

LogInfo("Cert setup complete for $env:ENV_BLAISE_CATI_URL")
