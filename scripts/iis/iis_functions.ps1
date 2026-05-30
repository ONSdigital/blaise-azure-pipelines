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

    $preCondition = Get-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -Name "."

    if ($null -eq $preCondition) {
        LogInfo("Creating NoCompression preCondition for $siteName...")
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression"}
    }

    $existingRules = @(Get-WebConfigurationProperty -pspath $sitePath -filter "$preConditionFilter/add" -Name "." -ErrorAction SilentlyContinue)
    $requiredRules = @(
        @{ input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate|br).*$"; label = "response encoding is not compressed" },
        @{ input = "{RESPONSE_CONTENT_TYPE}"; pattern = "^(text/|application/(json|javascript|xml|x-www-form-urlencoded)|application/xhtml\+xml)"; label = "response type is text" },
        @{ input = "{REQUEST_URI}"; pattern = "^(?!.*_blazor).*$"; label = "request is not Blazor realtime endpoint" }
    )

    foreach ($rule in $requiredRules) {
        $ruleWithInput = $existingRules | Where-Object {
            $_.input -eq $rule.input
        } | Select-Object -First 1

        if (-not $ruleWithInput) {
            LogInfo("Adding NoCompression condition for ${siteName}: $($rule.label)")
            Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $rule.input; pattern = $rule.pattern}
        }
        elseif ($ruleWithInput.pattern -ne $rule.pattern) {
            try {
                LogInfo("Updating NoCompression condition for ${siteName}: $($rule.label)")
                Remove-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -AtElement @{input = $rule.input} -ErrorAction Stop
                Add-WebConfigurationProperty -pspath $sitePath -filter $preConditionFilter -name "." -value @{input = $rule.input; pattern = $rule.pattern} -ErrorAction Stop
            }
            catch {
                # Keep legacy condition when IIS provider rejects in-place updates on existing environments.
                LogInfo("Keeping existing NoCompression condition for ${siteName}: $($rule.label)")
                LogInfo("Reason: $($_.Exception.Message)")
            }
        }
        else {
            LogInfo("NoCompression condition already exists for ${siteName}: $($rule.label)")
        }
    }

    LogInfo("NoCompression preCondition ensured for $siteName")
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
    $ruleFilter = "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']"
    $matchFilter = "$ruleFilter/match"
    $actionFilter = "$ruleFilter/action"

    function GetConfigString {
        param ([object] $value)

        if ($null -eq $value) {
            return ""
        }

        if ($value -is [string]) {
            return $value
        }

        if ($value.PSObject -and $value.PSObject.Properties["Value"]) {
            return [string] $value.Value
        }

        return [string] $value
    }

    if (-not (Test-Path $sitePath)) {
        LogInfo("Skipping $ruleName - site '$siteName' does not exist")
        return
    }

    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name "."
    $hasExpectedServerVariable = -not [string]::IsNullOrWhiteSpace($serverVariable)
    $expectedServerVariable = ""

    if ($hasExpectedServerVariable) {
        $expectedServerVariable = $serverVariable
    }

    try {
        $applyRuleDefinition = {
            Set-WebConfigurationProperty -pspath $sitePath -filter $matchFilter -name "pattern" -value "$rule"

            if ($hasExpectedServerVariable) {
                Set-WebConfigurationProperty -pspath $sitePath -filter $matchFilter -name "serverVariable" -value "$expectedServerVariable"
            }

            Set-WebConfigurationProperty -pspath $sitePath -filter $actionFilter -name "type" -value "Rewrite"
            Set-WebConfigurationProperty -pspath $sitePath -filter $actionFilter -name "value" -value "$serverName"
        }

        if (-not $ruleExists) {
            LogInfo("Adding rewrite URL rule '$ruleName' to site '$siteName'...")
            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}
        }
        else {
            LogInfo("Rewrite URL rule '$ruleName' already exists in site '$siteName', ensuring expected configuration...")
        }

        & $applyRuleDefinition

        $appliedPattern = GetConfigString (Get-WebConfigurationProperty -pspath $sitePath -filter $matchFilter -name "pattern")
        $appliedServerVariable = GetConfigString (Get-WebConfigurationProperty -pspath $sitePath -filter $matchFilter -name "serverVariable")
        $appliedActionType = GetConfigString (Get-WebConfigurationProperty -pspath $sitePath -filter $actionFilter -name "type")
        $appliedActionValue = GetConfigString (Get-WebConfigurationProperty -pspath $sitePath -filter $actionFilter -name "value")

        $ruleNeedsRebuild = ($appliedPattern -ne $rule) -or
            ($appliedActionType -ne "Rewrite") -or
            ($appliedActionValue -ne $serverName)

        if ($hasExpectedServerVariable) {
            $ruleNeedsRebuild = $ruleNeedsRebuild -or ($appliedServerVariable -ne $expectedServerVariable)
        }

        if ($ruleNeedsRebuild) {
            LogInfo("Rule '$ruleName' was not in expected state after update, rebuilding it...")

            if (Get-WebConfigurationProperty -pspath $sitePath -filter $ruleFilter -name ".") {
                Remove-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -AtElement @{name = $ruleName}
            }

            Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName}
            & $applyRuleDefinition
        }

        LogInfo("Rewrite URL rule '$ruleName' ensured on site '$siteName'")
    }
    catch {
        LogError("Failed to apply rewrite URL rule '$ruleName' for site '$siteName'")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }

    $existingPreCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter $ruleFilter -name "preCondition"

    if (-not [string]::IsNullOrWhiteSpace($preCondition)) {
        if ($existingPreCondition -ne $preCondition) {
            LogInfo("Setting $preCondition preCondition on rule '$ruleName' in $siteName...")
            Set-WebConfigurationProperty -pspath $sitePath `
                -filter $ruleFilter `
                -name "preCondition" -value "$preCondition"
            LogInfo("$preCondition preCondition set on '$ruleName' in $siteName")
        }
        else {
            LogInfo("$preCondition preCondition already set on '$ruleName'")
        }
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($existingPreCondition)) {
            LogInfo("Clearing preCondition on '$ruleName' in $siteName...")
            Set-WebConfigurationProperty -pspath $sitePath `
                -filter $ruleFilter `
                -name "preCondition" -value ""
            LogInfo("preCondition cleared on '$ruleName' in $siteName")
        }
        else {
            LogInfo("No preCondition set on '$ruleName'")
        }
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
