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

$encodedServerName = "https%3a%2f%2f$env:ENV_BLAISE_CATI_URL"

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists, failing!")
    exit 1
}

foreach ($site in $existingSites) {
    AddNoCompressionPreCondition -siteName $site
    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "https?://blaise-gusty-data[^/]*" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "https?://blaise-gusty-mgmt[^/]*" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise data entry encoded" -serverName $encodedServerName -rule "https?%3a%2f%2fblaise-gusty-data[^%]*" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt encoded" -serverName $encodedServerName -rule "https?%3a%2f%2fblaise-gusty-mgmt[^%]*" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise data entry location header" -serverName "https://$env:ENV_BLAISE_CATI_URL{R:2}" -rule "^https?://blaise-gusty-data(:\d+)?(.*)$" -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt location header" -serverName "https://$env:ENV_BLAISE_CATI_URL{R:2}" -rule "^https?://blaise-gusty-mgmt(:\d+)?(.*)$" -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise data entry encoded location header" -serverName $encodedServerName -rule "https?%3a%2f%2fblaise-gusty-data[^%]*" -serverVariable "RESPONSE_LOCATION" -preCondition ""
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt encoded location header" -serverName $encodedServerName -rule "https?%3a%2f%2fblaise-gusty-mgmt[^%]*" -serverVariable "RESPONSE_LOCATION" -preCondition ""
    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
