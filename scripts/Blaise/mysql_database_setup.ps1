. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

function ConfigurationChangesDetected {
    param (
        [string] $DatabaseFilePath
    )
    $configurationSettings = ListOfConfigurationSettings

    if ($configurationSettings.contains($DatabaseFilePath)) {
        Write-Host "No changes detected in $DatabaseFilePath. Blaise restart not required."   
        return $false
    
    }
    Write-Host "Changes detected in $DatabaseFilePath. Blaise restart is required."
    return $true
}

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

    $originalConfigurationSettings = ListOfConfigurationSettings

    #audit
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    CreateAndRegisterDataInterfaceFile -DatabaseFilePath $audit_db_file_path -ApplicationType audittrail -RegisterCommand audittraildatainterface

    #Session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    CreateAndRegisterDataInterfaceFile -DatabaseFilePath $session_db_file_path -ApplicationType session -RegisterCommand sessiondatainterface

    #Cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    CreateAndRegisterDataInterfaceFile -DatabaseFilePath $cati_db_file_path -ApplicationType cati -RegisterCommand catidatainterface
    
    #Config
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $config_file_path = "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config"

    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile $config_file_path -interfaceFileName "ConfigurationDataInterfaceFile"
    
    # # Restart Blaise if changes detected
    # if ($restartBlaise.Contains($true)) {
    #     Write-Host "Changes have been detected. Restarting Blaise..."
    #     restart-service blaiseservices5
    # } else {
    #     Write-Host "DEBUG: Blaise was not restarted :tada:"
    # }

    $NewConfigurationSettings = ListOfConfigurationSettings
    if ($originalConfigurationSettings -ne $newConfigurationSettings) {
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    } else {
        Write-Host "DEBUG 2: Blaise was not restarted :tada:"
    }

