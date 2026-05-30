. "$PSScriptRoot\..\logging_functions.ps1"
. "$PSScriptRoot\iis_functions.ps1"

if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    LogError("WebAdministration module not available")
    exit 1
}

Import-Module WebAdministration -ErrorAction Stop

CheckIfUrlRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

DisableCompression

$externalServerName = "https://$env:ENV_BLAISE_CATI_URL"
$encodedExternalServerName = [System.Uri]::EscapeDataString($externalServerName)
$escapedExternalServerName = $externalServerName.Replace("/", "\\/")

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists, failing!")
    exit 1
}

# Safety net for any leaked redirects to internal Blaise hosts.
AddInboundHostRedirectRule -ruleName "Blaise internal host redirect" -hostPattern '^blaise-[^\.]+-(mgmt|data)$'

foreach ($site in $existingSites) {
    AddNoCompressionPreCondition -siteName $site

    # Rewrite plain internal Blaise hosts emitted in HTML/text responses.
    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-data[^/\s"<>]*(/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-mgmt[^/\s"<>]*(/[^\s"<>]*)?'

    # Rewrite URL-encoded internal hosts used by newer dashboard StartSurvey links.
    AddRewriteRule -siteName $site -ruleName "Blaise data entry encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-data[^%\s"&<>]*(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-mgmt[^%\s"&<>]*(%2f[^\s"&<>]*)?'

    # Rewrite JSON-escaped internal hosts (for responses that emit http:\/\/host style strings).
    AddRewriteRule -siteName $site -ruleName "Blaise data entry escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-data[^\\/\s"<>]*(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-mgmt[^\\/\s"<>]*(\\/[^\s"<>]*)?'

    # Rewrite redirect Location headers that still point to internal hosts.
    AddRewriteRule -siteName $site -ruleName "Blaise data entry location header" -serverName "$externalServerName{R:1}" -rule '^https?://blaise-[^/\s"<>]*-data[^/\s"<>]*(/.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt location header" -serverName "$externalServerName{R:1}" -rule '^https?://blaise-[^/\s"<>]*-mgmt[^/\s"<>]*(/.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""

    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
    