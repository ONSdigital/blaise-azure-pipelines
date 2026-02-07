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

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists, failing!")
    exit 1
}

foreach ($site in $existingSites) {
    AddNoCompressionPreCondition -siteName $site
    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"
    RemoveWebDav -siteName $site

    $appPool = "$($site)AppPool"
    setTimeout -siteName $site -appPool $appPool
}
