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

CheckIfURLRewriteMsiExists
Write-Host "Install write url msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\dev\data\rewrite_url.msi /quiet'

$siteName = "Blaise"
$ruleName = "Blaise data entry"
$serverName = "https://$env:ENV_BLAISE_CATI_URL"

$existing = Get-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']" -Name "."

if ($existing){
    Write-Host "Re write rule already exists."
    exit 0
}

try{
    Write-Host "Adding rewrite rule"

    Add-WebConfigurationProperty -pspath "iis:\sites\Default Web Site\$siteName" -filter "system.webServer/rewrite/outboundrules" -name "." -value @{name=$ruleName}
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/match" -name "pattern" -value "http://blaise-gusty-data[^/]*"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "type" -value "Rewrite"
    Set-WebConfigurationProperty -pspath "MACHINE/WEBROOT/APPHOST/Default Web Site/$siteName"  -filter "system.webServer/rewrite/outboundRules/rule[@name='$ruleName']/action" -name "value" -value "$serverName"

    Write-Host "Rewrite rules applied"
}
catch{
    Write-Host $_.ScriptStackTrace
    Write-Host "Rewrite rules have not been applied"
    exit 1
}


