. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

    $originalConfiguration = ListOfConfigurationSettings
    $originalXmlConfiguration = [xml](Get-Content "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config")
    
    #audit
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    CreateDataInterfaceFile -filePath $audit_db_file_path -applicationType audittrail
    RegisterDataInterfaceFile -filePath $audit_db_file_path -registerCommand audittraildatainterface

    #Session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    CreateDataInterfaceFile -filePath $session_db_file_path -applicationType session
    RegisterDataInterfaceFile -filePath $session_db_file_path -registerCommand sessiondatainterface

    #Cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    CreateDataInterfaceFile -filePath $cati_db_file_path -applicationType cati
    RegisterDataInterfaceFile -filePath $cati_db_file_path -registerCommand catidatainterface

    #Config
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $config_file_path = "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config"
    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile $config_file_path -interfaceFileName "ConfigurationDataInterfaceFile"
    
    #Restart Blaise if required
    $newConfiguration = ListOfConfigurationSettings
    $newXmlConfiguration = [xml](Get-Content "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config")

    $configurationChangesDetected = $originalConfiguration -eq $newConfiguration
    $xmlConfigurationChangesDetected = $originalXmlConfiguration.InnerXml -eq $newXmlConfiguration.InnerXml

    if ($configurationChangesDetected -or $xmlConfigurationChangesDetected) {
        # Write-Host "Changes have been detected. Restarting Blaise..."
        Write-Host "DEBUG: Restarting Blaise even though there are no changes..."
        restart-service blaiseservices5
    } else {
        Write-Host "DEBUG: Blaise was not restarted :sob:"
    }