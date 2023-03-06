. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

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
    CreateDataInterfaceFile -filePath $config_db_file_path -applicationType configuration 
    RegisterDatainterfaceViaXML -filePath $config_db_file_path -configFile "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config" -interfaceFileName "ConfigurationDataInterfaceFile"

    #Credentials
    #Commenting out calling MySQL data interface creation for creds until upgrade to Blaise 5.13
    #$credentials_db_file_path = "D:\Blaise5\Settings\credentials.budi"
    #CreateDataInterfaceFile -filePath $credentials_db_file_path -applicationType credentials 
    #RegisterDataInterfaceFile -filePath $credentials_db_file_path -registerCommand credentialsdatainterface  

    restart-service blaiseservices5


