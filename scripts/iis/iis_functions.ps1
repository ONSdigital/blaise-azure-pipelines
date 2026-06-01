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
    $preConditionFilter = "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']"
    $expectedInput = "{RESPONSE_CONTENT_ENCODING}"
    $expectedPattern = "^(|identity)$"
    $expectedContentTypeInput = "{RESPONSE_CONTENT_TYPE}"
    $expectedContentTypePattern = "^(text/html|application/xhtml\\+xml|application/json|application/.+\\+json)(;.*)?$"
    $expectedRequestUriInput = "{REQUEST_URI}"
    $expectedRequestUriPattern = "^/_blazor(?:$|/)"

    $preCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter $preConditionFilter -Name "."

    if ($null -eq $preCondition) {
        LogInfo("Creating NoCompression preCondition for $siteName...")
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression"}
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedInput; pattern = $expectedPattern}
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedContentTypeInput; pattern = $expectedContentTypePattern}
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedRequestUriInput; pattern = $expectedRequestUriPattern; negate = "true"}
        LogInfo("NoCompression preCondition added successfully for $siteName")
    }
    else {
        # Reconcile existing NoCompression entries so this script remains idempotent across old deployments.
        Remove-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -ErrorAction SilentlyContinue
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedInput; pattern = $expectedPattern}
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedContentTypeInput; pattern = $expectedContentTypePattern}
        Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $expectedRequestUriInput; pattern = $expectedRequestUriPattern; negate = "true"}
        LogInfo("NoCompression preCondition refreshed for $siteName")
    }
}

function AddRewriteRule {
    param (
        [string] $siteName,
        [string] $ruleName,
        [string] $serverName = "https://$env:ENV_BLAISE_CATI_URL",
        [string] $rule,
        [string] $serverVariable = "",
        [string] $preCondition = "NoCompression"
    )

    $sitePath = "iis:\sites\Default Web Site\$siteName"

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping $ruleName - site '$siteName' does not exist")
        return
    }

    $ruleFilter = "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']"
    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "."

    if (-not $ruleExists) {
        try {
            LogInfo("Adding rewrite URL rule '$ruleName' to site '$siteName'...")

            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}
            LogInfo("Rewrite URL rule '$ruleName' created in site '$siteName'")
        }
        catch {
            LogError("Failed to create rewrite URL rule '$ruleName' for site '$siteName'")
            LogError("$($_.Exception.Message)")
            LogError("$($_.ScriptStackTrace)")
            exit 1
        }
    }
    else {
        LogInfo("Rewrite URL rule '$ruleName' already exists in site '$siteName', ensuring it has expected settings")
    }

    $applyRuleSettings = {
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/match" -name "pattern" -value "$rule"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/match" -name "ignoreCase" -value "true"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/match" -name "serverVariable" -value "$serverVariable"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "type" -value "Rewrite"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "value" -value "$serverName"
    }

    $readConfigValue = {
        param(
            [string] $filter,
            [string] $name
        )

        $rawValue = Get-WebConfigurationProperty -pspath $sitePath -filter $filter -name $name

        if ($null -eq $rawValue) {
            return ""
        }

        if ($rawValue -is [string]) {
            return $rawValue
        }

        if ($rawValue.PSObject.Properties.Name -contains "Value") {
            return [string] $rawValue.Value
        }

        return [string] $rawValue
    }

    $actionValueMatchesExpected = {
        param(
            [string] $actualActionValue
        )

        if ($actualActionValue -eq $serverName) {
            return $true
        }

        # Some IIS installs normalize outbound body rule values by dropping trailing {R:1}.
        if ([string]::IsNullOrWhiteSpace($serverVariable) -and ($serverName -match "\{R:1\}$")) {
            $withoutTrailingCapture = $serverName -replace "\{R:1\}$", ""
            if ($actualActionValue -eq $withoutTrailingCapture) {
                return $true
            }
        }

        # Some IIS installs normalize RESPONSE_LOCATION rule values by adding a capture suffix.
        if (-not [string]::IsNullOrWhiteSpace($serverVariable)) {
            if ($actualActionValue -eq "$serverName{R:0}" -or $actualActionValue -eq "$serverName{R:1}") {
                return $true
            }
        }

        return $false
    }

    $verifyRuleSettings = {
        $appliedPattern = & $readConfigValue "$ruleFilter/match" "pattern"
        $appliedServerVariable = & $readConfigValue "$ruleFilter/match" "serverVariable"
        $appliedActionType = & $readConfigValue "$ruleFilter/action" "type"
        $appliedActionValue = & $readConfigValue "$ruleFilter/action" "value"

        ($appliedPattern -eq $rule) -and
        ($appliedServerVariable -eq $serverVariable) -and
        ($appliedActionType -eq "Rewrite") -and
        (& $actionValueMatchesExpected $appliedActionValue)
    }

    try {
        & $applyRuleSettings
        LogInfo("Rewrite URL rule '$ruleName' applied to site '$siteName'")

        if (-not (& $verifyRuleSettings)) {
            LogInfo("Rule '$ruleName' did not persist expected values, recreating it in '$siteName'...")
            Remove-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -AtElement @{name = $ruleName}
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}

            & $applyRuleSettings

            if (-not (& $verifyRuleSettings)) {
                $actualPattern = & $readConfigValue "$ruleFilter/match" "pattern"
                $actualServerVariable = & $readConfigValue "$ruleFilter/match" "serverVariable"
                $actualActionValue = & $readConfigValue "$ruleFilter/action" "value"

                if ([string]::IsNullOrWhiteSpace($serverVariable)) {
                    LogInfo("Rule '$ruleName' could not be fully reconciled in '$siteName', continuing because this is a body rule")
                    LogInfo("Expected pattern='$rule', serverVariable='$serverVariable', actionValue='$serverName'")
                    LogInfo("Actual pattern='$actualPattern', serverVariable='$actualServerVariable', actionValue='$actualActionValue'")
                    LogInfo("IIS may have normalized the action value for this body rule")
                }
                elseif ($serverVariable -ieq "RESPONSE_LOCATION") {
                    LogInfo("Rule '$ruleName' could not be fully reconciled in '$siteName', continuing because this is a RESPONSE_LOCATION header rule")
                    LogInfo("Expected pattern='$rule', serverVariable='$serverVariable', actionValue='$serverName'")
                    LogInfo("Actual pattern='$actualPattern', serverVariable='$actualServerVariable', actionValue='$actualActionValue'")
                    LogInfo("IIS may have normalized this header rule on the target VM")
                }
                else {
                    LogError("Rewrite URL rule '$ruleName' could not be reconciled in '$siteName'")
                    LogError("Expected pattern='$rule', serverVariable='$serverVariable', actionValue='$serverName'")
                    LogError("Actual pattern='$actualPattern', serverVariable='$actualServerVariable', actionValue='$actualActionValue'")
                    LogError("Verify IIS URL Rewrite supports this action value on the target VM")
                    exit 1
                }
            }

            LogInfo("Rewrite URL rule '$ruleName' recreated successfully in '$siteName'")
        }
    }
    catch {
        LogError("Failed to configure rewrite URL rule '$ruleName' for site '$siteName'")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }

    $existingPreCondition = & $readConfigValue $ruleFilter "preCondition"

    if ([string]::IsNullOrWhiteSpace($preCondition)) {
        if (-not [string]::IsNullOrWhiteSpace($existingPreCondition)) {
            LogInfo("Removing preCondition from rule '$ruleName' in $siteName...")
            Set-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "preCondition" -value ""
            LogInfo("preCondition removed from '$ruleName' in $siteName")
        }
        else {
            LogInfo("No preCondition set on '$ruleName', no changes required")
        }
    }
    else {
        if ($existingPreCondition -ne $preCondition) {
            LogInfo("Setting $preCondition preCondition on rule '$ruleName' in $siteName...")
            Set-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "preCondition" -value $preCondition
            LogInfo("$preCondition preCondition set on '$ruleName' in $siteName")
        }
        else {
            LogInfo("$preCondition preCondition already set on '$ruleName'")
        }
    }
}

function AddInboundHostRedirectRule {
    param (
        [string] $ruleName,
        [string] $hostPattern,
        [string] $targetHost = "$env:ENV_BLAISE_CATI_URL"
    )

    $sitePath = "IIS:\Sites\Default Web Site"

    if (-not (Test-Path $sitePath)) {
        LogError("IIS site 'Default Web Site' does not exist")
        exit 1
    }

    $ruleFilter = "system.webServer/rewrite/rules/rule[@name='$ruleName']"
    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "."

    if (-not $ruleExists) {
        try {
            LogInfo("Adding inbound redirect rule '$ruleName'...")
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/rules" -name "." -value @{name = $ruleName; stopProcessing = "true"}
            Add-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/conditions" -name "." -value @{input = "{HTTP_HOST}"; pattern = $hostPattern}
            LogInfo("Inbound redirect rule '$ruleName' created")
        }
        catch {
            LogError("Failed to create inbound redirect rule '$ruleName'")
            LogError("$($_.Exception.Message)")
            LogError("$($_.ScriptStackTrace)")
            exit 1
        }
    }
    else {
        LogInfo("Inbound redirect rule '$ruleName' already exists, ensuring expected settings")
    }

    try {
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/match" -name "url" -value "(.*)"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter" -name "stopProcessing" -value "true"

        Remove-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/conditions" -name "." -ErrorAction SilentlyContinue
        Add-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/conditions" -name "." -value @{input = "{HTTP_HOST}"; pattern = $hostPattern}

        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "type" -value "Redirect"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "url" -value "https://$targetHost/{R:1}"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "appendQueryString" -value "true"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "redirectType" -value "Found"

        LogInfo("Inbound redirect rule '$ruleName' applied")
    }
    catch {
        LogError("Failed to configure inbound redirect rule '$ruleName'")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

function AddInboundPathAndQueryRedirectRule {
    param (
        [string] $siteName,
        [string] $ruleName,
        [string] $pathPattern,
        [string] $queryPattern,
        [string] $targetUrl
    )

    $sitePath = "IIS:\Sites\Default Web Site\$siteName"

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping inbound query redirect rule '$ruleName' - site '$siteName' does not exist")
        return
    }

    $ruleFilter = "system.webServer/rewrite/rules/rule[@name='$ruleName']"
    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "."

    if (-not $ruleExists) {
        try {
            LogInfo("Adding inbound query redirect rule '$ruleName' to site '$siteName'...")
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/rules" -name "." -value @{name = $ruleName; stopProcessing = "true"}
            LogInfo("Inbound query redirect rule '$ruleName' created in site '$siteName'")
        }
        catch {
            LogError("Failed to create inbound query redirect rule '$ruleName' for site '$siteName'")
            LogError("$($_.Exception.Message)")
            LogError("$($_.ScriptStackTrace)")
            exit 1
        }
    }
    else {
        LogInfo("Inbound query redirect rule '$ruleName' already exists in site '$siteName', ensuring expected settings")
    }

    try {
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/match" -name "url" -value $pathPattern
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter" -name "stopProcessing" -value "true"

        Remove-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/conditions" -name "." -ErrorAction SilentlyContinue
        Add-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/conditions" -name "." -value @{input = "{QUERY_STRING}"; pattern = $queryPattern; ignoreCase = "true"}

        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "type" -value "Redirect"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "url" -value $targetUrl
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "appendQueryString" -value "false"
        Set-WebConfigurationProperty -pspath $sitePath -filter "$ruleFilter/action" -name "redirectType" -value "Found"

        LogInfo("Inbound query redirect rule '$ruleName' applied to site '$siteName'")
    }
    catch {
        LogError("Failed to configure inbound query redirect rule '$ruleName' for site '$siteName'")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
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
