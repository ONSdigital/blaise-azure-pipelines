. "$PSScriptRoot\..\logging_functions.ps1"

function CheckIfUrlRewriteMsiExists {
    if (Test-Path "C:\dev\data\rewrite_url.msi") {
        LogInfo("rewrite_url.msi already downloaded")
    }
    else {
        LogInfo("Downloading rewrite_url.msi...")
        gsutil cp gs://$env:ENV_BLAISE_GCP_BUCKET/rewrite_url.msi "C:\dev\data\rewrite_url.msi"
    }
}

function AddRewriteRule {
    param (
        [string] $siteName,
        [string] $ruleName,
        [string] $serverName,
        [string] $rule
    )

    $sitePath = "iis:\sites\Default Web Site\$siteName"

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping $ruleName – site '$siteName' does not exist")
        return
    }

    $existing = Get-WebConfigurationProperty -pspath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" `
        -Name "."

    if ($existing) {
        LogInfo("Rewrite URL rule '$ruleName' already exists in site '$siteName'")
        return
    }

    try {
        LogInfo("Adding rewrite URL rule '$ruleName' to site '$siteName'...")

        Add-WebConfigurationProperty -pspath $sitePath `
            -filter "system.webServer/rewrite/outboundrules" `
            -name "." -value @{name = $ruleName }

        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" `
            -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" `
            -name "pattern" -value "$rule"

        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" `
            -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" `
            -name "type" -value "Rewrite"

        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" `
            -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" `
            -name "value" -value "$serverName"

        LogInfo("Rewrite URL rule '$ruleName' applied to site '$siteName'")
    }
    catch {
        LogError("Failed to apply rewrite URL rule '$ruleName' to site '$siteName'")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

CheckIfUrlRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists – failing")
    exit 1
}

foreach ($site in $existingSites) {
    AddRewriteRule -siteName $site -ruleName "Blaise data entry" `
        -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"

    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" `
        -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"
}
