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
$doubleEncodedExternalServerName = [System.Uri]::EscapeDataString($encodedExternalServerName)
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
    AddRewriteRule -siteName $site -ruleName "Blaise localhost" -serverName "$externalServerName{R:1}" -rule 'https?://localhost(/[^\s"<>]*)?'

    # Rewrite URL-encoded internal hosts used by newer dashboard StartSurvey links.
    AddRewriteRule -siteName $site -ruleName "Blaise data entry encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-data[^%\s"&<>]*(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-mgmt[^%\s"&<>]*(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2flocalhost(%2f[^\s"&<>]*)?'

    # Rewrite double-encoded internal hosts used in ReturnUrl values, e.g. http%253a%252f%252fblaise-... .
    AddRewriteRule -siteName $site -ruleName "Blaise data entry double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252fblaise-[^%\s"&<>]*-data[^%\s"&<>]*(%252f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252fblaise-[^%\s"&<>]*-mgmt[^%\s"&<>]*(%252f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252flocalhost(%252f[^\s"&<>]*)?'

    # Rewrite JSON-escaped internal hosts (for responses that emit http:\/\/host style strings).
    AddRewriteRule -siteName $site -ruleName "Blaise data entry escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-data[^\\/\s"<>]*(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-mgmt[^\\/\s"<>]*(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/localhost(\\/[^\s"<>]*)?'

    # Rewrite redirect Location headers that still point to internal hosts.
    AddRewriteRule -siteName $site -ruleName "Blaise data entry location header" -serverName "$externalServerName{R:1}" -rule '^https?://blaise-[^/\s"<>]*-data[^/\s"<>]*(/.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt location header" -serverName "$externalServerName{R:1}" -rule '^https?://blaise-[^/\s"<>]*-mgmt[^/\s"<>]*(/.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise localhost location header" -serverName "$externalServerName{R:1}" -rule '^https?://localhost(/.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""

    # Rewrite internal hosts embedded within Location query params (url=...) for new dashboard flows.
    AddRewriteRule -siteName $site -ruleName "Blaise location header url plain" -serverName '{R:1}'"$externalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?://blaise-[^/\s"<>]*-(?:mgmt|data)[^/\s"<>]*(/[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header url encoded" -serverName '{R:1}'"$encodedExternalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?%3a%2f%2fblaise-[^%\s"<>]*-(?:mgmt|data)[^%\s"<>]*(%2f[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header url double encoded" -serverName '{R:1}'"$doubleEncodedExternalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?%253a%252f%252fblaise-[^%\s"<>]*-(?:mgmt|data)[^%\s"<>]*(%252f[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header localhost plain" -serverName '{R:1}'"$externalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?://localhost(/[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header localhost encoded" -serverName '{R:1}'"$encodedExternalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?%3a%2f%2flocalhost(%2f[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header localhost double encoded" -serverName '{R:1}'"$doubleEncodedExternalServerName"'{R:2}{R:3}' -rule '^(.+url=)https?%253a%252f%252flocalhost(%252f[^&\s"<>]*)?(&.*)?$' -serverVariable "RESPONSE_LOCATION" -preCondition ""

    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
    