. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

    CreateAndRegisterDataInterfaceFile -filePath "D:\Blaise5\Settings\audittraildb.badi" -applicationType audittrail -registerCommand audittraildatainterface
    CreateAndRegisterDataInterfaceFile -filePath "D:\Blaise5\Settings\sessiondb.bsdi" -applicationType session -registerCommand sessiondatainterface
    CreateAndRegisterDataInterfaceFile -filePath "D:\Blaise5\Settings\catidb.bcdi" -applicationType cati -registerCommand catidatainterface
    
    restart-service blaiseservices5


