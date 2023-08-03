. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

function DataInterfaceCreated {
    param (
        [array] $RestartBlaise
    )
    return $RestartBlaise.Contains($true)
}

function ConfigurationChanged{
    $newConfiguration = ListOfConfigurationSettings
    $newXmlConfiguration = [xml](Get-Content "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config")

    $configurationChangesDetected = $originalConfiguration -ne $newConfiguration
    $xmlConfigurationChangesDetected = $originalXmlConfiguration.InnerXml -ne $newXmlConfiguration.InnerXml

    if (-Not ($xmlConfigurationChangesDetected -or $configurationChangesDetected )) {
        return $false
    }

    return $true
}

function BlaiseRestartRequired{
    param ([array] $RestartBlaise)
    if (-Not (ConfigurationChanged -or DataInterfaceCreated -RestartBlaise $RestartBlaise)) {
        return $false
    }
    return $true
}

    $originalConfiguration = ListOfConfigurationSettings
    $originalXmlConfiguration = [xml](Get-Content "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config")
    $newDataInterfaceCreated = ,$false
    
    #audit
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $audit_db_file_path -applicationType audittrail
    RegisterDataInterfaceFile -filePath $audit_db_file_path -registerCommand audittraildatainterface

    #Session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $session_db_file_path -applicationType session
    RegisterDataInterfaceFile -filePath $session_db_file_path -registerCommand sessiondatainterface

    #Cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $cati_db_file_path -applicationType cati
    RegisterDataInterfaceFile -filePath $cati_db_file_path -registerCommand catidatainterface

    #Config
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config" -interfaceFileName "ConfigurationDataInterfaceFile"

    #Credentials
    #Commenting out calling MySQL data interface creation for creds until upgrade to Blaise 5.13
    # $credentials_db_file_path = "D:\Blaise5\Settings\credentials.budi"
    # $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $credentials_db_file_path -applicationType credentials
    # RegisterDataInterfaceFile -filePath $credentials_db_file_path -registerCommand credentialsdatainterface

    #Restart Blaise if required
    # TRIGGER A RESTART!!!
    # $originalConfiguration = $originalConfiguration.Replace('D:\Blaise5\Settings\audittraildb.badi','TRIGGERED!')

    if (BlaiseRestartRequired -RestartBlaise $newDataInterfaceCreated){
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    }