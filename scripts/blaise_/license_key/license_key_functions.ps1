. "$PSScriptRoot\..\..\logging_functions.ps1"

function SetBlaiseLicenseViaRegistry {
    param(
        [string] $Blaise_License_Key,
        [string] $Blaise_Activation_Code
    )
    if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
        $licenseInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey'
        $activationInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode'

        if ($licenseInfo.LicenseKey -eq $Blaise_License_Key) {
            LogInfo("License key is correct: $($Blaise_License_Key)")
        }
        else {
            LogInfo("License key is out of date, updating...")
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $Blaise_License_Key
            LogInfo("License key updated to: $($Blaise_License_Key)")
        }

        if ($activationInfo.ActivationCode -eq $Blaise_Activation_Code) {
            LogInfo("Activation code is correct: $($Blaise_Activation_Code)")
        }
        else {
            LogInfo("Activation code is out of date, updating...")
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $Blaise_Activation_Code
            LogInfo("Activation code updated to: $($Blaise_Activation_Code)")
        }
    }
    else {
        LogInfo("No registry key found for Blaise")
    }
}
