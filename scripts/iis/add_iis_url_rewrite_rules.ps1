. "$PSScriptRoot\..\logging_functions.ps1"

function CheckIfURLRewriteMsiExists {
  If (Test-Path "C:\dev\data\rewrite_url.msi") {
    LogInfo("rewrite_url.msi already downloaded")
  }
  else {
    LogInfo("Downloading rewrite_url.msi...")
    gsutil cp gs://$env:ENV_BLAISE_GCP_BUCKET/rewrite_url.msi "C:\dev\data\rewrite_url.msi"
  }
}

function EnsureNoCompressionPreConditionExists {
    $preConditionExists = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site" -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']" -Name "."

    if ($null -eq $preConditionExists) {
        LogInfo("Creating NoCompression preCondition...")
        Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site" -filter "system.webServer/rewrite/outboundRules/preConditions" -name "." -value @{name = "NoCompression" }
        Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site" -filter "system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='NoCompression']/add" -name "." -value @{input = "{RESPONSE_CONTENT_ENCODING}"; pattern = "^(?!gzip|deflate)$" }
        LogInfo("NoCompression preCondition added successfully.")
    }
    else {
        LogInfo("NoCompression preCondition already exists. Skipping creation.")
    }
}

function AddRewriteRule {
  param (
    [string] $siteName,
    [string] $ruleName,
    [string] $serverName = "https://$env:ENV_BLAISE_CATI_URL",
    [string] $rule
  )

  $existingRule = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -Name "."

  if ($existingRule) {
    LogInfo("Rewrite URL rule $ruleName already exists.")

    # Check if the rule already has 'NoCompression' preCondition
    $existingPreConditions = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/preCondition" -name "."

    if ($existingPreConditions -match "NoCompression") {
      LogInfo("NoCompression preCondition already set for rule $ruleName. Skipping update.")
    }
    else {
      LogInfo("Adding NoCompression preCondition to existing rule $ruleName...")
      Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/preCondition" -name "." -value "NoCompression"
      LogInfo("NoCompression preCondition added to $ruleName.")
    }
    return
  }

  try {
    LogInfo("Adding $ruleName rewrite URL rule...")

    Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules" -name "." -value @{name = $ruleName }
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

    # Check if NoCompression is already set for this rule before adding it
    $existingPreConditions = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/preCondition" -name "."

    if ($existingPreConditions -notmatch "NoCompression") {
      Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/preCondition" -name "." -value "NoCompression"
      LogInfo("NoCompression preCondition added to $ruleName.")
    }

    LogInfo("Rewrite URL rule $ruleName applied.")
  }
  catch {
    LogError("Rewrite URL rules have not been applied")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
  }
}

CheckIfURLRewriteMsiExists
LogInfo("Installing rewrite_url.msi...")
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

EnsureNoCompressionPreConditionExists

AddRewriteRule -siteName "BlaiseDashboard" -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
AddRewriteRule -siteName "BlaiseDashboard" -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"
