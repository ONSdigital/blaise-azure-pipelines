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

function GetWebConfigurationPropertySafe {
    param (
        [string] $psPath,
        [string] $filter,
        [string] $name = ".",
        [string] $context = ""
    )

    try {
        return Get-WebConfigurationProperty -pspath $psPath -filter $filter -name $name -ErrorAction Stop
    }
    catch {
        $contextSuffix = if ($context) { " ($context)" } else { "" }
        LogInfo("Could not read IIS configuration$contextSuffix for filter '$filter'. Treating as missing. Error: $($_.Exception.Message)")
        return $null
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
    LogInfo("URL compression settings updated successfully")
}

function AddNoCompressionPreCondition {
    param ([string] $siteName)

    $sitePath = "iis:\sites\Default Web Site\$siteName"

    $preCondition = GetWebConfigurationPropertySafe -psPath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -Name "." `
        -context "$siteName NoCompression preCondition"

    if ($null -eq $preCondition) {
        LogInfo("Creating NoCompression preCondition for $siteName...")
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression"}
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$"}
        LogInfo("NoCompression preCondition added successfully for $siteName")
    }
    else {
        $existingRule = GetWebConfigurationPropertySafe -psPath $sitePath `
            -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']/add" -Name "." `
            -context "$siteName NoCompression preCondition add"
        if (-not $existingRule) {
            LogInfo("Adding input and pattern to existing NoCompression preCondition for $siteName...")
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$"}
        }
        else {
            LogInfo("NoCompression preCondition already exists for $siteName")
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

    $ruleExists = GetWebConfigurationPropertySafe -psPath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -Name "." `
        -context "$siteName outbound rule $ruleName"

    if (-not $ruleExists) {
        try {
            LogInfo("Adding rewrite URL rule '$ruleName' to site '$siteName'...")

            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
            Set-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

            LogInfo("Rewrite URL rule '$ruleName' applied to site '$siteName'")
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

    $existingPreCondition = GetWebConfigurationPropertySafe -psPath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -Name "preCondition" `
        -context "$siteName outbound rule $ruleName preCondition"

    if ($existingPreCondition -ne "NoCompression") {
        LogInfo("Setting NoCompression preCondition on rule '$ruleName' in $siteName...")
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" `
            -name "preCondition" -value "NoCompression"
        LogInfo("NoCompression preCondition set on '$ruleName' in $siteName")
    }
    else {
        LogInfo("NoCompression preCondition already set on '$ruleName'")
    }
}

function RemoveWebDav {
    param ([string] $siteName)
    $sitePath = "IIS:\Sites\Default Web Site\$siteName"

    LogInfo("Removing WebDAV from $siteName...")

    $moduleFilter = "system.webServer/modules/add[@name='WebDAVModule']"
    if (Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/modules" -name "collection" | Where-Object { $_.name -eq "WebDAVModule" }) {
        Remove-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/modules" -name "collection" -AtElement @{name="WebDAVModule"}
    }

    if (Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/handlers" -name "collection" | Where-Object { $_.name -eq "WebDAV" }) {
        Remove-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/handlers" -name "collection" -AtElement @{name="WebDAV"}
    }
}

function currentTimeoutValues {
    param (
        [string] $siteName,
        [string] $appPoolName
    )

    $currentSessionStateTimeout = (Get-WebConfigurationProperty `
        -filter system.web/sessionState `
        -name Timeout `
        -PSPath "IIS:\Sites\Default Web Site\$siteName").Value

    $currentIdleTimeout = (Get-ItemProperty ("IIS:\AppPools\$appPoolName")).processModel.idleTimeout

    return $currentSessionStateTimeout, $currentIdleTimeout
}

function timeoutIsSetCorrectly {
    param (
        [string] $currentSessionTimeout,
        [string] $currentIdleTimeout,
        [string] $expectedTimeout
    )
    ($currentSessionTimeout -eq $expectedTimeout) -and ($currentIdleTimeout -eq $expectedTimeout)
}

function setTimeout {
    param (
        [string] $siteName,
        [string] $appPool
    )

    [string] $expectedTimeout = "08:00:00"

    $currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues -siteName $siteName -appPoolName $appPool
    $setTimeout = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout

    if (-not $setTimeout) {
        Set-WebConfigurationProperty system.web/sessionState "IIS:\Sites\Default Web Site\$siteName" -Name "Timeout" -Value:$expectedTimeout
        Set-ItemProperty ("IIS:\AppPools\$appPool") -Name processModel.idleTimeout -value $expectedTimeout

        LogInfo("IIS timeout changes made, restarting $appPool...")
        Restart-WebAppPool $appPool
        LogInfo("$appPool has been restarted")
    }
    else {
        LogInfo("IIS timeout changes already applied for $siteName / $appPool")
    }
}

function AddInboundStartSurveyRedirectRule {
    param ([string] $siteName)

    $sitePath = "IIS:\Sites\Default Web Site\$siteName"
    $ruleName = "Blaise StartSurvey inbound redirect"

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping '$ruleName' - site '$siteName' does not exist")
        return
    }

    $ruleFilter = "system.webServer/rewrite/rules/rule[@name='$ruleName']"
    $ruleExists = GetWebConfigurationPropertySafe -psPath $sitePath -filter $ruleFilter -Name "." `
        -context "$siteName inbound rule $ruleName"

    if (-not $ruleExists) {
        try {
            LogInfo("Adding inbound StartSurvey redirect rule to '$siteName'...")
            Add-WebConfigurationProperty -pspath $sitePath `
                -filter "system.webServer/rewrite/rules" `
                -name "." `
                -value @{name = $ruleName; stopProcessing = "true"}
            LogInfo("Rule '$ruleName' created in '$siteName'")
        }
        catch {
            LogError("Failed to create '$ruleName' for '$siteName'")
            LogError("$($_.Exception.Message)")
            exit 1
        }
    }
    else {
        LogInfo("Rule '$ruleName' already exists in '$siteName', updating settings...")
    }

    try {
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/match" -name "url" `
            -value "^(?:BlaiseDashboard/)?CaseInfo/StartSurvey$"

        Set-WebConfigurationProperty -pspath $sitePath `
            -filter $ruleFilter -name "stopProcessing" -value "true"

        Remove-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/conditions" -name "." -ErrorAction SilentlyContinue

        Add-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/conditions" -name "." `
            -value @{
                input       = "{QUERY_STRING}"
                pattern     = "^url=https?(%3a|:)(%2f|/)(%2f|/)(?:blaise-[^%/&]*-(?:mgmt|data)|localhost(?:(%3a|:)\d+)?)(%2f|/)([^&]*)(.*)"
                ignoreCase  = "true"
            }

        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/action" -name "type" -value "Redirect"
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/action" -name "url" `
            -value "https://$env:ENV_BLAISE_CATI_URL/BlaiseDashboard/CaseInfo/StartSurvey?url=https%3a%2f%2f$env:ENV_BLAISE_CATI_URL%2f{C:6}{C:7}"
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/action" -name "appendQueryString" -value "false"
        Set-WebConfigurationProperty -pspath $sitePath `
            -filter "$ruleFilter/action" -name "redirectType" -value "Found"

        LogInfo("Rule '$ruleName' applied to '$siteName'")
    }
    catch {
        LogError("Failed to configure '$ruleName' for '$siteName'")
        LogError("$($_.Exception.Message)")
        exit 1
    }
}
