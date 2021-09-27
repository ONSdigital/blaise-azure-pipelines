. "$PSScriptRoot\..\helpers\update_environment_variables.ps1"
. "$PSScriptRoot\update_blaise_license.ps1"

$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)

if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
    SetBlaiseLicenseViaRegistry
}
else {
    New-Item -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $BLAISE_SERIALNUMBER
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $BLAISE_ACTIVATIONCODE
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'Licensee' -value "ONS"
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'CompanyName' -value "ONS"
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'UserName' -value 'ONS-USER'
}
