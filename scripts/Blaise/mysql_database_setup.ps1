. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

function RestartBlaiseRequired {
    param (
        [string] $filePath
    )
    $configurationSettings = ListOfConfigurationSettings
    Write-Host "DEBUG: configurationSettings: $configurationSettings"

    if ($configurationSettings.contains($filePath)) {
        Write-Host "No configuration changes detected in $filePath. Blaise restart not required."   
        return false
    
    }
    Write-Host "Configuration changes detected in $filePath. Blaise restart is required."
    return true
}

    $restartBlaise = ,false

    #audit
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    $restartBlaise += RestartBlaiseRequired -filePath $audit_db_file_path
    CreateDataInterfaceFile -filePath $audit_db_file_path -applicationType audittrail
    RegisterDataInterfaceFile -filePath $audit_db_file_path -registerCommand audittraildatainterface

    #Session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    $restartBlaise += RestartBlaiseRequired -filePath $session_db_file_path
    CreateDataInterfaceFile -filePath $session_db_file_path -applicationType session
    RegisterDataInterfaceFile -filePath $session_db_file_path -registerCommand sessiondatainterface

    #Cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    $restartBlaise += RestartBlaiseRequired -filePath $cati_db_file_path
    CreateDataInterfaceFile -filePath $cati_db_file_path -applicationType cati
    RegisterDataInterfaceFile -filePath $cati_db_file_path -registerCommand catidatainterface

    #Config
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $xml = [xml](Get-Content $configFile)

    if (-Not $xml.InnerXml.Contains($filePath))
    {
        $restartBlaise += true
    }

    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config" -interfaceFileName "ConfigurationDataInterfaceFile"

    #Credentials
    #Commenting out calling MySQL data interface creation for creds until upgrade to Blaise 5.13
    #$credentials_db_file_path = "D:\Blaise5\Settings\credentials.budi"
    #CreateDataInterfaceFile -filePath $credentials_db_file_path -applicationType credentials
    #RegisterDataInterfaceFile -filePath $credentials_db_file_path -registerCommand credentialsdatainterface

    if ($restartBlaise.Contains(true)) {
        Write-Host "Configuration changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    }
