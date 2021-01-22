
function Check_Blaise_Is_Installed{

$app = Get-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object { $_.DisplayName -match 'blaise' } |Select-Object DisplayName, DisplayVersion, InstallDate, Version 

  if (!$app){
   return "##vso[task.setvariable variable=BlaiseInstalled;]False"
  }
  else
  {
  return "##vso[task.setvariable variable=BlaiseInstalled;]True"
  }

}

Write-Host check_blaise_Is_Installed
