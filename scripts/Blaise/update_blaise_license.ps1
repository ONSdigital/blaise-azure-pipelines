. "$PSScriptRoot\..\helpers\update_environment_variables.ps1"

$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)

$licenseInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey'
$activationInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode'

if ($licenseInfo.LicenseKey -eq $BLAISE_SERIALNUMBER)
{
    Write-Host "Serial number is correct: $($BLAISE_SERIALNUMBER)"
}
else
{
    Write-Host "Serial number is out of date"
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $BLAISE_SERIALNUMBER
    Write-Host "Serial number updated to: $($BLAISE_SERIALNUMBER)"
}

if ($activationInfo.ActivationCode -eq $BLAISE_ACTIVATIONCODE)
{
    Write-Host "Activation code is correct: $($BLAISE_ACTIVATIONCODE)"
}
else
{
    Write-Host "Activation code is out of date"
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $BLAISE_ACTIVATIONCODE
    Write-Host "Activation code updated to: $($BLAISE_ACTIVATIONCODE)"
}
