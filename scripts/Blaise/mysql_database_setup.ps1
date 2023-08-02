. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

function XMLConfigurationChangesDetected {
    param (
        [string] $DatabaseFilePath,
        [string] $ConfigFilePath
    )
    $xml = [xml](Get-Content $ConfigFilePath)

    if($xml.InnerXml.Contains($DatabaseFilePath)){
        Write-Host "No changes detected in $DatabaseFilePath. Blaise restart not required."   
        return $false
    }
    Write-Host "Changes detected in $DatabaseFilePath. Blaise restart is required."
    return $true
}
    $originalConfiguration = ListOfConfigurationSettings
    $originalXmlConfiguration = [xml](Get-Content "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config")
    Write-Host "DEBUG: originalXmlConfiguration: $originalXmlConfiguration"

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
    $restartBlaise += XMLConfigurationChangesDetected -DatabaseFilePath $config_db_file_path -ConfigFilePath $config_file_path
    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile $config_file_path -interfaceFileName "ConfigurationDataInterfaceFile"
    
    #Restart Blaise if required
    $newConfiguration = ListOfConfigurationSettings
    if ($originalConfiguration -ne $newConfiguration) {
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    } else {
        Write-Host "DEBUG 3: Blaise was not restarted :tada:"
    }

