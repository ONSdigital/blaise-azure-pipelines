# Needed for Blaise versions running dashboard on .NET
# Allows redirected Blaise self-referential HTTPS calls to localhost to be trusted

. "$PSScriptRoot\logging_functions.ps1"

# Ensure all errors are terminating
$ErrorActionPreference = "Stop"

if (-not ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.16")) {
    LogInfo("Local cert not required for Blaise $env:ENV_BLAISE_CURRENT_VERSION")
    return
}

if (-not $env:COMPUTERNAME) {
    LogError("Hostname not defined - cannot create cert")
    exit 1
}

# Check if cert already exists
$subject = "CN=$env:COMPUTERNAME"
$existingCert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object { $_.Subject -eq $subject }
if (-not $existingCert) {
    try {
        LogInfo("Creating new self-signed cert for $env:COMPUTERNAME...")

        $cert = New-SelfSignedCertificate `
            -DnsName $env:COMPUTERNAME `
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

# Check if cert is already trusted
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

# Check if SSL binding already exists
$bindings = netsh http show sslcert | Out-String
if ($bindings -match $cert.Thumbprint) {
    LogInfo("SSL binding already exists for this cert")
}
else {
    try {
        LogInfo("Creating SSL binding on 0.0.0.0:443...")
        netsh http add sslcert ipport=0.0.0.0:443 certhash=$cert.Thumbprint appid='{00112233-4455-6677-8899-AABBCCDDEEFF}'
    }
    catch {
        LogError("Failed to create SSL binding")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

LogInfo("Cert setup complete for $hostname")
