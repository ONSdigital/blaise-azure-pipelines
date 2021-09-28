   
function SetBlaiseLicenseViaRegistry {
    if (Test-Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0') {
        $licenseInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey'
        $activationInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode'

        if ($licenseInfo.LicenseKey -eq $env:Blaise_License_Key)
        {
            Write-Host "Serial number is correct: $($env:Blaise_License_Key)"
        }
        else
        {
            Write-Host "Serial number is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'LicenseKey' -value $env:Blaise_License_Key
            Write-Host "Serial number updated to: $($env:Blaise_License_Key)"
        }

        if ($activationInfo.ActivationCode -eq $env:Blaise_Activation_Code)
        {
            Write-Host "Activation code is correct: $($env:Blaise_Activation_Code)"
        }
        else
        {
            Write-Host "Activation code is out of date"
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\StatNeth\Blaise\5.0' -Name 'ActivationCode' -value $env:Blaise_Activation_Code
            Write-Host "Activation code updated to: $($env:Blaise_Activation_Code)"
        }
    }
    else 
    {
        Write-Host "No registry key found for Blaise"
    }
}

SetBlaiseLicenseViaRegistry
