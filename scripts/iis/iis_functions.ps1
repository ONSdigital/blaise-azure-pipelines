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

    $preCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -Name "."

    if ($null -eq $preCondition) {
        LogInfo("Creating NoCompression preCondition for $siteName...")
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression"}
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$"}
        LogInfo("NoCompression preCondition added successfully for $siteName")
    }
    else {
        $existingRule = Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']/add" -Name "."
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

    $ruleExists = Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -name "."

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

    $existingPreCondition = Get-WebConfigurationProperty -pspath $sitePath `
        -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -name "preCondition"

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

    $aspNetCoreHandler = Get-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/handlers" -name "collection" | Where-Object { $_.name -eq "aspNetCore" }
    if ($null -eq $aspNetCoreHandler) {
        Add-WebConfigurationProperty -pspath $sitePath -filter "system.webServer/handlers" -name "collection" -value @{name='aspNetCore'; path='*'; verb='*'; modules='AspNetCoreModuleV2'}
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
