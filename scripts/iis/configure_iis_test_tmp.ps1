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

function SetGlobalAllowedServerVariables {
    $variableNames = @("HTTP_ACCEPT_ENCODING", "HTTP_X_ORIGINAL_ACCEPT_ENCODING")
    $appCmdPath = "$env:WINDIR\System32\inetsrv\appcmd.exe"

    foreach ($variableName in $variableNames) {
        & $appCmdPath set config -section:system.webServer/rewrite/allowedServerVariables /-"[name='$variableName']" /commit:apphost 2>$null
        & $appCmdPath set config -section:system.webServer/rewrite/allowedServerVariables /+"[name='$variableName']" /commit:apphost
        LogInfo("Ensured global allowed server variable: $variableName")
    }
}

if (-not ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.16")) {
    LogInfo("Running configure IIS for Blaise 5.14")
    & "$PSScriptRoot\configure_iis_514.ps1"
    return
}

CheckIfUrlRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

SetGlobalAllowedServerVariables

$siteName = "BlaiseDashboard"
$catiUrl = "https://$env:ENV_BLAISE_CATI_URL"

$site = Get-WebApplication -Site "Default Web Site" -Name $siteName
if (-not $site) {
    LogError("Site $siteName not found!")
    exit 1
}

$webConfigPath = Join-Path $site.PhysicalPath "web.config"
if (-not (Test-Path $webConfigPath)) {
    LogError("web.config file for site $SiteName not found!")
    exit 1
}

LogInfo("Configuring web.config for $siteName at $webConfigPath")

try {
    [xml]$xml = Get-Content $webConfigPath
    $configChanged = $false

    $locationSystemWebServer = $xml.SelectSingleNode("//location[@path='.']/system.webServer")

    $appInitSection = $locationSystemWebServer.SelectSingleNode("applicationInitialization")
    if (-not $appInitSection) {
        $appInitSection = $locationSystemWebServer.PrependChild($xml.CreateElement("applicationInitialization"))
        $appInitSection.SetAttribute("doAppInitAfterRestart", "true")
        $configChanged = $true
    }

    $initPagePath = "/BlaiseDashboard/Report"
    $initPageNode = $appInitSection.SelectSingleNode("add[@initializationPage='$initPagePath']")
    if (-not $initPageNode) {
        $initPageNode = $appInitSection.AppendChild($xml.CreateElement("add"))
        $initPageNode.SetAttribute("initializationPage", $initPagePath)
        $configChanged = $true
    }

    $aspNetCoreNode = $locationSystemWebServer.SelectSingleNode("aspNetCore")
    if ($aspNetCoreNode) {
    $envVarsNode = $aspNetCoreNode.SelectSingleNode("environmentVariables")
    if (-not $envVarsNode) {
        $envVarsNode = $aspNetCoreNode.AppendChild($xml.CreateElement("environmentVariables"))
        $configChanged = $true
    }

    $envVarDefinitions = @{
        "ASPNETCORE_ENVIRONMENT" = "Production";
        "Logging__LogLevel__Default" = "Information";
        "ASPNETCORE_APPL_PATH" = "/BlaiseDashboard";
        "ASPNETCORE_FORWARDEDHEADERS_ENABLED" = "true" 
    }

    foreach ($envName in $envVarDefinitions.Keys) {
        $envNode = $envVarsNode.SelectSingleNode("environmentVariable[@name='$envName']")
        if (-not $envNode) {
            $envNode = $envVarsNode.AppendChild($xml.CreateElement("environmentVariable"))
            $envNode.SetAttribute("name", $envName)
            $configChanged = $true
        }

        if ($envNode.GetAttribute("value") -ne $envVarDefinitions[$envName]) {
            $envNode.SetAttribute("value", $envVarDefinitions[$envName])
            $configChanged = $true
        }
    }
}

    $modulesSection = $locationSystemWebServer.SelectSingleNode("modules")
    if (-not $modulesSection) { $modulesSection = $locationSystemWebServer.PrependChild($xml.CreateElement("modules")); $configChanged = $true }
    if (-not $modulesSection.SelectSingleNode("remove[@name='WebDAVModule']")) {
        $removeNode = $modulesSection.AppendChild($xml.CreateElement("remove"))
        $removeNode.SetAttribute("name", "WebDAVModule")
        $configChanged = $true
    }

    $handlersSection = $locationSystemWebServer.SelectSingleNode("handlers")
    if (-not $handlersSection) { 
        if ($modulesSection) { $handlersSection = $locationSystemWebServer.InsertAfter($xml.CreateElement("handlers"), $modulesSection) }
        else { $handlersSection = $locationSystemWebServer.PrependChild($xml.CreateElement("handlers")) }
        $configChanged = $true 
    }
    if (-not $handlersSection.SelectSingleNode("remove[@name='WebDAV']")) {
        $removeNode = $handlersSection.PrependChild($xml.CreateElement("remove"))
        $removeNode.SetAttribute("name", "WebDAV")
        $configChanged = $true
    }

    $httpProtocolSection = $locationSystemWebServer.SelectSingleNode("httpProtocol")
    if (-not $httpProtocolSection) { $httpProtocolSection = $locationSystemWebServer.AppendChild($xml.CreateElement("httpProtocol")); $configChanged = $true }
    $customHeadersSection = $httpProtocolSection.SelectSingleNode("customHeaders")
    if (-not $customHeadersSection) { $customHeadersSection = $httpProtocolSection.AppendChild($xml.CreateElement("customHeaders")); $configChanged = $true }
    
    $headerDefinitions = @{ "X-Forwarded-Proto" = "https"; "X-Forwarded-For" = "{REMOTE_ADDR}" }
    foreach ($headerName in $headerDefinitions.Keys) {
        $headerNode = $customHeadersSection.SelectSingleNode("add[@name='$headerName']")
        if (-not $headerNode) { 
            $headerNode = $customHeadersSection.AppendChild($xml.CreateElement("add"))
            $headerNode.SetAttribute("name", $headerName)
            $configChanged = $true
        }
        $headerNode.SetAttribute("value", $headerDefinitions[$headerName])
    }

    $rewriteSection = $locationSystemWebServer.SelectSingleNode("rewrite")
    if (-not $rewriteSection) { $rewriteSection = $locationSystemWebServer.AppendChild($xml.CreateElement("rewrite")); $configChanged = $true }

    $inboundRules = $rewriteSection.SelectSingleNode("rules")
    if (-not $inboundRules) { $inboundRules = $rewriteSection.AppendChild($xml.CreateElement("rules")); $configChanged = $true }
    if (-not $inboundRules.SelectSingleNode("rule[@name='StripAcceptEncoding']")) {
        $ruleNode = $inboundRules.AppendChild($xml.CreateElement("rule"))
        $ruleNode.SetAttribute("name", "StripAcceptEncoding"); $ruleNode.SetAttribute("stopProcessing", "false")
        $ruleNode.AppendChild($xml.CreateElement("match")).SetAttribute("url", ".*")
        $serverVariables = $ruleNode.AppendChild($xml.CreateElement("serverVariables"))
        $serverVariables.AppendChild($xml.CreateElement("set")).SetAttribute("name", "HTTP_X_ORIGINAL_ACCEPT_ENCODING"); $serverVariables.LastChild.SetAttribute("value", "{HTTP_ACCEPT_ENCODING}")
        $serverVariables.AppendChild($xml.CreateElement("set")).SetAttribute("name", "HTTP_ACCEPT_ENCODING"); $serverVariables.LastChild.SetAttribute("value", "")
        $ruleNode.AppendChild($xml.CreateElement("action")).SetAttribute("type", "None")
        $configChanged = $true
    }

    $outboundRules = $rewriteSection.SelectSingleNode("outboundRules")
    if (-not $outboundRules) { $outboundRules = $rewriteSection.AppendChild($xml.CreateElement("outboundRules")); $configChanged = $true }

    function EnsureOutboundRule {
        param ($parentSection, $ruleName, $preConditionName, $matchPattern, $actionValue, $stopProcessing, $matchServerVariable)
        if (-not $parentSection.SelectSingleNode("rule[@name='$ruleName']")) {
            $newRule = $parentSection.AppendChild($xml.CreateElement("rule")); $newRule.SetAttribute("name", $ruleName)
            if ($preConditionName) { $newRule.SetAttribute("preCondition", $preConditionName) }
            if ($stopProcessing) { $newRule.SetAttribute("stopProcessing", $stopProcessing) }
            
            $matchNode = $newRule.AppendChild($xml.CreateElement("match"))
            if ($matchServerVariable) { $matchNode.SetAttribute("serverVariable", $matchServerVariable) }
            $matchNode.SetAttribute("pattern", $matchPattern)

            $actionNode = $newRule.AppendChild($xml.CreateElement("action"))
            if ($actionValue -eq "None") { $actionNode.SetAttribute("type", "None") }
            else { $actionNode.SetAttribute("type", "Rewrite"); $actionNode.SetAttribute("value", $actionValue) }
            return $true
        }
        return $false
    }

    $addedRestoreRule = EnsureOutboundRule -parentSection $outboundRules -ruleName "RestoreAcceptEncoding" -preConditionName "NeedsRestoringAcceptEncoding" -matchServerVariable "HTTP_ACCEPT_ENCODING" -matchPattern "^(.*)" -actionValue "{HTTP_X_ORIGINAL_ACCEPT_ENCODING}"
    $addedWebSocketRule = EnsureOutboundRule -parentSection $outboundRules -ruleName "Ignore Blazor WebSockets" -stopProcessing "true" -matchPattern "/_blazor/.*" -actionValue "None"
    $addedDataEntryRule = EnsureOutboundRule -parentSection $outboundRules -ruleName "Blaise data entry" -preConditionName "NoCompression" -matchPattern "http://blaise-gusty-data[^/]*" -actionValue $catiUrl
    $addedMgmtRule = EnsureOutboundRule -parentSection $outboundRules -ruleName "Blaise mgmt" -preConditionName "NoCompression" -matchPattern "http://blaise-gusty-mgmt*" -actionValue $catiUrl
    if ($addedRestoreRule -or $addedWebSocketRule -or $addedDataEntryRule -or $addedMgmtRule) { $configChanged = $true }

    $preConditionsSection = $outboundRules.SelectSingleNode("preConditions")
    if (-not $preConditionsSection) { $preConditionsSection = $outboundRules.AppendChild($xml.CreateElement("preConditions")); $configChanged = $true }
    
    function EnsurePreCondition {
        param ($parentSection, $conditionName, $inputString, $patternString)
        $existingCond = $parentSection.SelectSingleNode("preCondition[@name='$conditionName']")
        if (-not $existingCond) {
            $newCondition = $parentSection.AppendChild($xml.CreateElement("preCondition")); $newCondition.SetAttribute("name", $conditionName)
            $addNode = $newCondition.AppendChild($xml.CreateElement("add"))
            $addNode.SetAttribute("input", $inputString)
            $addNode.SetAttribute("pattern", $patternString)
            return $true
        } else {
            $addNode = $existingCond.SelectSingleNode("add")
            if ($addNode.GetAttribute("input") -ne $inputString) {
                $addNode.SetAttribute("input", $inputString)
                return $true
            }
        }
        return $false
    }

    $addedNoCompressionPreCond = EnsurePreCondition -parentSection $preConditionsSection -conditionName "NoCompression" -inputString "{RESPONSE_CONTENT_ENCODING}" -patternString "^(?!gzip|deflate)$"
    $addedRestorePreCond = EnsurePreCondition -parentSection $preConditionsSection -conditionName "NeedsRestoringAcceptEncoding" -inputString "{HTTP_X_ORIGINAL_ACCEPT_ENCODING}" -patternString ".+"
    if ($addedNoCompressionPreCond -or $addedRestorePreCond) { $configChanged = $true }

    $urlCompression = $locationSystemWebServer.SelectSingleNode("urlCompression")
    if (-not $urlCompression) { $urlCompression = $locationSystemWebServer.AppendChild($xml.CreateElement("urlCompression")); $configChanged = $true }
    if ($urlCompression.GetAttribute("doStaticCompression") -ne "false") { $urlCompression.SetAttribute("doStaticCompression", "false"); $configChanged = $true }
    if ($urlCompression.GetAttribute("doDynamicCompression") -ne "false") { $urlCompression.SetAttribute("doDynamicCompression", "false"); $configChanged = $true }

    if ($configChanged) {
        $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
        $xmlWriterSettings.Indent = $true
        $xmlWriterSettings.IndentChars = "  "
        $xmlWriterSettings.NewLineChars = "`r`n"
        $xmlWriter = [System.Xml.XmlWriter]::Create($webConfigPath, $xmlWriterSettings)
        $xml.Save($xmlWriter)
        $xmlWriter.Close()
        LogInfo("Successfully updated web.config")
    } else {
        LogInfo("No changes required to web.config")
    }

} catch {
    LogError("Failed to update web.config")
    LogError("$($_.Exception.Message)")
    exit 1
}

LogInfo("IIS configuration completed successfully")
