. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

try {
    $filePath = "D:\Blaise5\Settings\catidb.bcdi"
    #Create data interface
    CreateDataInterfaceFile -applicationType cati -filePath $filePath
    Write-Host "Created Cati Data Interface File"

    #register data interface
    RegisterCatiDataInterfaceFile -filePath $filePath
    restart-service blaiseservices5
    Write-Host ".bcdi file registered"
}
catch {
    Write-Host "Error occured updated Cati database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
}

