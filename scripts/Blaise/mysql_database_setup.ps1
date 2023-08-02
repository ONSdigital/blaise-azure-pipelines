. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

function RestartBlaiseRequired {
    param (
        [string] $filePath
    )
    $configurationSettings = ListOfConfigurationSettings

    if ($configurationSettings.contains($filePath)) {
        Write-Host "No changes detected in $filePath. Blaise restart not required."   
        return $false
    
    }
    Write-Host "Changes detected in $filePath. Blaise restart is required."
    return $true
}

    $restartBlaise = ,$false

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
    $config_file = "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config"
    
    $xml = [xml](Get-Content $config_file)

    $txtFragment = @"
    <add key="$interfaceFileName" value="$config_db_file_path"/>
"@

    if(-Not $xml.InnerXml.Contains($config_db_file_path)){
        Write-Host "Changes detected in $config_db_file_path. Blaise restart is required."   
        $restartBlaise += $true
    } else {
        Write-Host "No changes detected in $config_db_file_path. Blaise restart not required."
    }

    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile $config_file -interfaceFileName "ConfigurationDataInterfaceFile"

    Write-Host "DEBUG: restartBlaise: $restartBlaise"

    if ($restartBlaise.Contains($true)) {
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    } else {
        Write-Host "DEBUG: Blaise was not restarted :tada:"
    }
