$app = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version 

if (!$app){
 Write-Host "##vso[task.setvariable variable=BlaiseInstalled;isOutput=true]False"
}
else
{
Write-Host "Blaise Version " + $app.DisplayVersion + " is installed"
Write-Host "##vso[task.setvariable variable=BlaiseInstalled;isOutput=true]True"
Invoke-Expression "$currentPath\scripts\blaise\BlaiseUrlRewrite.ps1"

    if ($app.DisplayVersion -eq $env:ENV_BLAISE_CURRENT_VERSION)
    {
        Write-Host "Blaise is currently on the correct version"
        Write-Host "##vso[task.setvariable variable=UpgradeBlaise;isOutput=true]False" 
    }
    else {
        Write-Host "Blaise need to be upgraded to the latest version"
        Write-Host "##vso[task.setvariable variable=UpgradeBlaise;isOutput=true]True"       
    }
}

