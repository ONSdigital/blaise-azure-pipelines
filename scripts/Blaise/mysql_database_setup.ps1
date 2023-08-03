. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

    $newDataInterfaceCreated = ,$false
    $newDataInterfaceRegistered = ,$false
    
    #audit
    $audit_db_file_path = "D:\Blaise5\Settings\audittraildb.badi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $audit_db_file_path -applicationType audittrail
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $audit_db_file_path -registerCommand audittraildatainterface

    #Session
    $session_db_file_path = "D:\Blaise5\Settings\sessiondb.bsdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $session_db_file_path -applicationType session
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $session_db_file_path -registerCommand sessiondatainterface

    #Cati
    $cati_db_file_path = "D:\Blaise5\Settings\catidb.bcdi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $cati_db_file_path -applicationType cati
    $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $cati_db_file_path -registerCommand catidatainterface

    #Config
    $config_db_file_path = "D:\Blaise5\Settings\configurationdb.bidi"
    $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration
    $newDataInterfaceRegistered += RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config" -interfaceFileName "ConfigurationDataInterfaceFile"

    #Credentials
    #Commenting out calling MySQL data interface creation for creds until upgrade to Blaise 5.13
    # $credentials_db_file_path = "D:\Blaise5\Settings\credentials.budi"
    # $newDataInterfaceCreated += CreateDataInterfaceFile -filePath $credentials_db_file_path -applicationType credentials
    # $newDataInterfaceRegistered += RegisterDataInterfaceFile -filePath $credentials_db_file_path -registerCommand credentialsdatainterface

    if ($NewDataInterfaceCreated.Contains($true) -or $NewDataInterfaceRegistered.Contains($true)){
        Write-Host "Changes have been detected. Restarting Blaise..."
        restart-service blaiseservices5
    }