# Rewrites internal Blaise URLs to external URLs

. "$PSScriptRoot\..\logging_functions.ps1"

if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    LogError("WebAdministration module not available")
    exit 1
}
Import-Module WebAdministration -ErrorAction Stop

function CheckIfUrlRewriteMsiExists {
    if (Test-Path "C:\dev\data\rewrite_url.msi") {
        LogInfo("rewrite_url.msi already downloaded")
    }
    else {
        LogInfo("Downloading rewrite_url.msi...")
        gsutil cp gs://$env:ENV_BLAISE_GCP_BUCKET/rewrite_url.msi "C:\dev\data\rewrite_url.msi"
    }
}

function DisableCompression {
    $compressionPath = "system.webServer/urlCompression"

    $existingConfig = Get-WebConfigurationProperty -pspath "IIS:\Sites\Default Web Site" -filter $compressionPath -name "."

    if ($existingConfig -eq $null) {
        LogInfo("Adding urlCompression section to Web.config...")
        New-WebConfigurationProperty -pspath "IIS:\Sites\Default Web Site" -filter "system.webServer" -name "." -value @{doStaticCompression="false"; doDynamicCompression="false"}
    }
    else {
        LogInfo("Updating existing urlCompression settings...")
        Set-WebConfigurationProperty -pspath "IIS:\Sites\Default Web Site" -filter $compressionPath -name "doStaticCompression" -value "false"
        Set-WebConfigurationProperty -pspath "IIS:\Sites\Default Web Site" -filter $compressionPath -name "doDynamicCompression" -value "false"
    }
    LogInfo("URL Compression settings updated successfully.")
}

function EnsureNoCompressionPreConditionExists {
    param ([string] $siteName)

    $sitePath = "iis:\sites\Default Web Site\$siteName"

    $preCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -Name "."

    if ($null -eq $preCondition) {
        LogInfo("Creating NoCompression preCondition for $siteName...")
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression"}
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$"}
        LogInfo("NoCompression preCondition added successfully for $siteName.")
    }
    else {
        $existingRule = Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']/add" -Name "."
        if (-not $existingRule) {
            LogInfo("Adding input+pattern to existing NoCompression preCondition for $siteName...")
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$"}
        }
        else {
            LogInfo("NoCompression preCondition already exists for $siteName with input+pattern.")
        }
    }
}

function AddRewriteRule {
    param (
        [string] $siteName,
        [string] $ruleName,
        [string] $serverName = "https://$env:ENV_BLAISE_CATI_URL",
        [string] $rule
    )

    $sitePath = "iis:\sites\Default Web Site\$siteName"

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping $ruleName - site '$siteName' does not exist")
        return
    }

    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -name "."

    if (-not $ruleExists) {
        try {
            LogInfo("Adding rewrite URL rule '$ruleName' to site '$siteName'...")

            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

            LogInfo("Rewrite URL rule '$ruleName' applied to site '$siteName'.")
        }
        catch {
            LogError("Failed to create rewrite URL rule '$ruleName' for site '$siteName'")
            LogError("$($_.Exception.Message)")
            LogError("$($_.ScriptStackTrace)")
            exit 1
        }
    }
    else {
        LogInfo("Rewrite URL rule '$ruleName' already exists in site '$siteName'")
    }

    # Always enforce NoCompression precondition
    $existingPreCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -name "preCondition"

    if ($existingPreCondition -ne "NoCompression") {
        LogInfo("Setting NoCompression preCondition on rule '$ruleName' in $siteName...")
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" `
            -name "preCondition" -value "NoCompression"
        LogInfo("NoCompression preCondition set on '$ruleName'.")
    }
    else {
        LogInfo("NoCompression preCondition already set on '$ruleName'.")
    }
}

CheckIfUrlRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

DisableCompression

$sites = @("Blaise", "BlaiseDashboard")
$existingSites = $sites | Where-Object { Test-Path "iis:\sites\Default Web Site\$_" }

if (-not $existingSites) {
    LogError("Neither 'Blaise' nor 'BlaiseDashboard' IIS site exists - failing")
    exit 1
}

foreach ($site in $existingSites) {
    EnsureNoCompressionPreConditionExists -siteName $site

    AddRewriteRule -siteName $site -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
    AddRewriteRule -siteName $site -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"
}
