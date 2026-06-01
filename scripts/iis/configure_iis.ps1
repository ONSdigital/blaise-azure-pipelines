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

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists, failing!")
    exit 1
}

foreach ($site in $existingSites) {
    AddNoCompressionPreCondition -siteName $site
    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName $externalServerName -rule "http://blaise-gusty-data[^/]*"
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName $externalServerName -rule "http://blaise-gusty-mgmt*"

    if ($site -eq "BlaiseDashboard") {
        AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url encoded" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=http%3a%2f%2fblaise-gusty-mgmt(%2f[^\s"&<>]*)?'
        AddRewriteRule -siteName $site -ruleName "Blaise StartSurvey url encoded localhost" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=http%3a%2f%2flocalhost(%3a[0-9]+)?(%2f[^\s"&<>]*)?'
        AddResponseLocationRewriteRule -siteName $site -ruleName "Blaise StartSurvey url encoded header" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=http%3a%2f%2fblaise-gusty-mgmt(%2f[^\s"&<>]*)?'
        AddResponseLocationRewriteRule -siteName $site -ruleName "Blaise StartSurvey url encoded header localhost" -serverName "url=$encodedExternalServerName{R:1}" -rule 'url=http%3a%2f%2flocalhost(%3a[0-9]+)?(%2f[^\s"&<>]*)?'
        AddResponseLocationRewriteRule -siteName $site -ruleName "Blaise StartSurvey header host" -serverName "$externalServerName{R:1}" -rule 'http://blaise-gusty-mgmt([^\s"&<>]*)?'
        AddResponseLocationRewriteRule -siteName $site -ruleName "Blaise StartSurvey header localhost" -serverName "$externalServerName{R:2}" -rule 'http://localhost(:[0-9]+)?([^\s"&<>]*)?'
        AddRewriteRule -siteName $site -ruleName "Blaise localhost" -serverName $externalServerName -rule 'http://localhost(:[0-9]+)?'
        AddRewriteRule -siteName $site -ruleName "Blaise localhost encoded" -serverName $encodedExternalServerName -rule 'http%3a%2f%2flocalhost(%3a[0-9]+)?'
    }

    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
