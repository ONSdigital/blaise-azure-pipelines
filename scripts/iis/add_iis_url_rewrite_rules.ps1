. "$PSScriptRoot\..\logging_functions.ps1"

# Needed for Blaise versions running dashboard on .NET Framework
# Rewrites internal Blaise URLs to external URLs

function CheckIfUrlRewriteMsiExists {
    If (Test-Path "C:\dev\data\rewrite_url.msi") {
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
        [string] $serverName = "https://$env:ENV_BLAISE_CATI_URL",
        [string] $rule
    )

    $existing = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -Name "."

    if ($existing) {
        LogInfo("Rewrite URL rule $ruleName already exists")
        return
    }

    try {
        LogInfo("Adding $ruleName rewrite URL rule...")
        Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundrules" -name "." -value @{name = $ruleName }
        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
        Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"
        LogInfo("Rewrite URL rule $ruleName applied")
    }
    catch {
        LogError("Rewrite URL rules have not been applied")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

if ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.16") {
    LogInfo("IIS URL rewrite rules not required for Blaise $env:ENV_BLAISE_CURRENT_VERSION")
    # could remove old "Blaise" site and app pool here if upgrading from older version...
    return
}

if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    throw "WebAdministration module not available"
}
Import-Module WebAdministration -ErrorAction Stop

CheckIfUrlRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'
AddRewriteRule -siteName "Blaise" -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"
