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

AddInboundHostRedirectRule -ruleName "Blaise internal host redirect" -hostPattern '^(blaise-[^\.]+-(mgmt|data)|localhost)(?::\d+)?$'

foreach ($site in $existingSites) {
    AddNoCompressionPreCondition -siteName $site

    if ($site -eq "Blaise") {
        AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-data[^/\s"<>]*(/[^\s"<>]*)?'
        AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-mgmt[^/\s"<>]*(/[^\s"<>]*)?'

        RemoveWebDav -siteName $site

        $appPool = "$($site)AppPool"
        setTimeout -siteName $site -appPool $appPool
        continue
    }

    if ($site -eq "BlaiseDashboard") {
        AddInboundPathAndQueryRedirectRule -siteName $site -ruleName "Blaise StartSurvey query redirect plain" -pathPattern '^(?:BlaiseDashboard/)?CaseInfo/StartSurvey$' -queryPattern '^url=https?://(?:blaise-[^/&]*-(?:mgmt|data)|localhost(?::\d+)?)(/[^&]*)(?:&(.*))?$' -targetUrl "https://$env:ENV_BLAISE_CATI_URL/BlaiseDashboard/CaseInfo/StartSurvey?url=$externalServerName{C:1}&{C:2}"
        AddInboundPathAndQueryRedirectRule -siteName $site -ruleName "Blaise StartSurvey query redirect encoded" -pathPattern '^(?:BlaiseDashboard/)?CaseInfo/StartSurvey$' -queryPattern '^url=https?%3a%2f%2f(?:blaise-[^%&]*-(?:mgmt|data)|localhost(?:%3a\d+)?)(%2f[^&]*)(?:&(.*))?$' -targetUrl "https://$env:ENV_BLAISE_CATI_URL/BlaiseDashboard/CaseInfo/StartSurvey?url=$encodedExternalServerName{C:1}&{C:2}"
        AddInboundPathAndQueryRedirectRule -siteName $site -ruleName "Blaise StartSurvey query redirect double encoded" -pathPattern '^(?:BlaiseDashboard/)?CaseInfo/StartSurvey$' -queryPattern '^url=https?%253a%252f%252f(?:blaise-[^%&]*-(?:mgmt|data)|localhost(?:%253a\d+)?)(%252f[^&]*)(?:&(.*))?$' -targetUrl "https://$env:ENV_BLAISE_CATI_URL/BlaiseDashboard/CaseInfo/StartSurvey?url=$doubleEncodedExternalServerName{C:1}&{C:2}"
    }

    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-data[^/\s"<>]*(/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "$externalServerName{R:1}" -rule 'https?://blaise-[^/\s"<>]*-mgmt[^/\s"<>]*(/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost" -serverName "$externalServerName{R:1}" -rule 'https?://localhost(?::\d+)?(/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url plain" -serverName "url=$externalServerName{R:1}" -rule 'url=https?://(?:blaise-[^/\s"<>]*-(?:mgmt|data)|localhost(?::\d+)?)(/[^\s"<>&]*)?'

    AddRewriteRule -siteName $site -ruleName "Blaise data entry encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-data[^%\s"&<>]*(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2fblaise-[^%\s"&<>]*-mgmt[^%\s"&<>]*(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost encoded" -serverName "$encodedExternalServerName{R:1}" -rule 'https?%3a%2f%2flocalhost(?:%3a\d+)?(%2f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url encoded" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=https?%3a%2f%2f(?:blaise-[^%\s"&<>]*-(?:mgmt|data)|localhost(?:%3a\d+)?)(%2f[^\s"&<>]*)?'

    AddRewriteRule -siteName $site -ruleName "Blaise data entry double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252fblaise-[^%\s"&<>]*-data[^%\s"&<>]*(%252f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252fblaise-[^%\s"&<>]*-mgmt[^%\s"&<>]*(%252f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost double encoded" -serverName "$doubleEncodedExternalServerName{R:1}" -rule 'https?%253a%252f%252flocalhost(?:%253a\d+)?(%252f[^\s"&<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url double encoded" -serverName "url=$doubleEncodedExternalServerName{R:1}" -rule 'url=https?%253a%252f%252f(?:blaise-[^%\s"&<>]*-(?:mgmt|data)|localhost(?:%253a\d+)?)(%252f[^\s"&<>]*)?'

    AddRewriteRule -siteName $site -ruleName "Blaise data entry escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-data[^\\/\s"<>]*(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/blaise-[^\\/\s"<>]*-mgmt[^\\/\s"<>]*(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise localhost escaped" -serverName "$escapedExternalServerName{R:1}" -rule 'https?:\\/\\/localhost(?::\d+)?(\\/[^\s"<>]*)?'
    AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url escaped" -serverName "url=$escapedExternalServerName{R:1}" -rule 'url=https?:\\/\\/(?:blaise-[^\\/\s"<>]*-(?:mgmt|data)|localhost(?::\d+)?)(\\/[^\s"<>&]*)?'

    AddRewriteRule -siteName $site -ruleName "Blaise location header inline host" -serverName "$externalServerName" -rule 'https?://blaise-[^/\s"<>]*-(?:mgmt|data)[^/\s"<>]*' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header inline host encoded" -serverName "$encodedExternalServerName" -rule 'https?%3a%2f%2fblaise-[^%\s"<>]*-(?:mgmt|data)[^%\s"<>]*' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header inline host double encoded" -serverName "$doubleEncodedExternalServerName" -rule 'https?%253a%252f%252fblaise-[^%\s"<>]*-(?:mgmt|data)[^%\s"<>]*' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header inline localhost" -serverName "$externalServerName" -rule 'https?://localhost(?::\d+)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header inline localhost encoded" -serverName "$encodedExternalServerName" -rule 'https?%3a%2f%2flocalhost(?:%3a\d+)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header inline localhost double encoded" -serverName "$doubleEncodedExternalServerName" -rule 'https?%253a%252f%252flocalhost(?:%253a\d+)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""

    AddRewriteRule -siteName $site -ruleName "Blaise location header url param plain" -serverName "url=$externalServerName{R:1}" -rule 'url=https?://(?:blaise-[^/\s"<>]*-(?:mgmt|data)|localhost(?::\d+)?)(/[^\s"<>&]*)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header url param encoded" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=https?%3a%2f%2f(?:blaise-[^%\s"&<>]*-(?:mgmt|data)|localhost(?:%3a\d+)?)(%2f[^\s"&<>]*)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise location header url param double encoded" -serverName "url=$doubleEncodedExternalServerName{R:1}" -rule 'url=https?%253a%252f%252f(?:blaise-[^%\s"&<>]*-(?:mgmt|data)|localhost(?:%253a\d+)?)(%252f[^\s"&<>]*)?' -serverVariable "RESPONSE_LOCATION" -preCondition ""

    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
