. "$PSScriptRoot\data_interface_functions.ps1"

    $newDataInterfaceCreated = ,$false
    $newDataInterfaceRegistered = ,$false
    
    # audittrail
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $audit_db_file_path -applicationType audittrail
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $audit_db_file_path -registerCommand audittraildatainterface

    # session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $session_db_file_path -applicationType session
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $session_db_file_path -registerCommand sessiondatainterface

    # cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $cati_db_file_path -applicationType cati
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $cati_db_file_path -registerCommand catidatainterface

    # configuration
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    $newDataInterfaceRegistered += RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config" -interfaceFileName "ConfigurationDataInterfaceFile"

    # credentials
    # not supported until Blaise version upgrade
    # $credentials_db_file_path = "D:\Blaise5\Settings\credentials.budi"
    # $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $credentials_db_file_path -applicationType credentials
    # $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $credentials_db_file_path -registerCommand credentialsdatainterface

    if ($NewDataInterfaceCreated.Contains($true) -or $NewDataInterfaceRegistered.Contains($true)){
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    }