function CheckIfURLRewriteMsiExists {
    If (Test-Path "C:\dev\data\rewrite_url.msi")
    {
      Write-Output "Skipping as Rewrite URL already downloaded..."
    }
    else
    {
      Write-Output "Downloading rewrite_url.msi"
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

  if ($existing){
      Write-Output "$ruleName already exists."
      return
  }

  try{
    Write-Output "Adding rewrite rule"

    Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundrules" -name "." -value @{name=$ruleName}
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

    Write-Output "$ruleName applied"
  }
  catch{
      Write-Output $_.Exception.Message
      Write-Output "Rewrite rules have not been applied"
      exit 1
  }
}

CheckIfURLRewriteMsiExists
Write-Output "Install write url msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

AddRewriteRule -siteName "Blaise" -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt*"