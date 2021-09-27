
function SetBlaiseLicenseViaRegistry {
    if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
        $licenseInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey'
        $activationInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode'

        if ($licenseInfo.LicenseKey -eq $env:ENV_BLAISE_LICENSE_KEY)
        {
            Write-Host "Serial number is correct: $($env:ENV_BLAISE_LICENSE_KEY)"
        }
        else
        {
            Write-Host "Serial number is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $env:ENV_BLAISE_LICENSE_KEY
            Write-Host "Serial number updated to: $($env:ENV_BLAISE_LICENSE_KEY)"
        }

        if ($activationInfo.ActivationCode -eq $env:ENV_BLAISE_ACTIVATION_CODE)
        {
            Write-Host "Activation code is correct: $($env:ENV_BLAISE_ACTIVATION_CODE)"
        }
        else
        {
            Write-Host "Activation code is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $env:ENV_BLAISE_ACTIVATION_CODE
            Write-Host "Activation code updated to: $($env:ENV_BLAISE_ACTIVATION_CODE)"
        }
    }
    else 
    {
        Write-Host "No registry key found for Blaise"
    }
}

SetBlaiseLicenseViaRegistry


