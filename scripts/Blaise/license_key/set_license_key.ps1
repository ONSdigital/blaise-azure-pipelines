param ([string]$BLAISE_LICENSE_KEY, [string]$BLAISE_ACTIVATION_CODE)

. "$PSScriptRoot\license_key_functions.ps1"

if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
    SetBlaiseLicenseViaRegistry $($BLAISE_LICENSE_KEY) $($BLAISE_ACTIVATION_CODE)
}
else {
    New-Item -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $($BLAISE_LICENSE_KEY)
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $($BLAISE_ACTIVATION_CODE)
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'Licensee' -value "ONS"
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'CompanyName' -value "Office for National Statistics"
    New-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'UserName' -value 'ONS-USER'
}