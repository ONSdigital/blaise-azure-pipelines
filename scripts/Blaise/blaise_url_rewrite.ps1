function CheckIfURLRewriteMsiExists {
    If (Test-Path "C:\dev\data\rewrite_url.msi") 
    {
      Write-Host "Skipping as Rewrite URL already downloaded..."
    }
    else
    {
      Write-Host "Downloading rewrite_url.msi"
      gsutil cp gs://$GCP_BUCKET/rewrite_url.msi "C:\dev\data\rewrite_url.msi"
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
      Write-Host "$ruleName already exists."
  }

  try{
    Write-Host "Adding rewrite rule"

    Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundrules" -name "." -value @{name=$ruleName}
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "$rule"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

    Write-Host "$ruleName applied"
  }
  catch{
      Write-Host $_.ScriptStackTrace
      Write-Host "Rewrite rules have not been applied"
      exit 1
  }
}

CheckIfURLRewriteMsiExists
Write-Host "Install write url msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

AddRewriteRule -siteName "Blaise" -ruleName "Blaise data entry" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-data[^/]*"
AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://$env:ENV_BLAISE_CATI_URL" -rule "http://blaise-gusty-mgmt/*"




