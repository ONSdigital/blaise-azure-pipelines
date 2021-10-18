function SetBlaiseLicenseViaRegistry {
    param(
        [string] $Blaise_License_Key,
        [string] $Blaise_Activation_Code
    )
    if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
        $licenseInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey'
        $activationInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode'

        if ($licenseInfo.LicenseKey -eq $Blaise_License_Key)
        {
            Write-Host "Serial number is correct: $($Blaise_License_Key)"
        }
        else
        {
            Write-Host "Serial number is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $Blaise_License_Key
            Write-Host "Serial number updated to: $($Blaise_License_Key)"
        }

        if ($activationInfo.ActivationCode -eq $Blaise_Activation_Code)
        {
            Write-Host "Activation code is correct: $($Blaise_Activation_Code)"
        }
        else
        {
            Write-Host "Activation code is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $Blaise_Activation_Code
            Write-Host "Activation code updated to: $($Blaise_Activation_Code)"
        }
    }
    else 
    {
        Write-Host "No registry key found for Blaise"
    }
}
