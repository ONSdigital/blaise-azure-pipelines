$app = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version 

if (!$app){
 Write-Host "##vso[task.setvariable variable=BlaiseInstalled;isOutput=true]False"
}
else
{
Write-Host "##vso[task.setvariable variable=BlaiseInstalled;isOutput=true]True"
}

