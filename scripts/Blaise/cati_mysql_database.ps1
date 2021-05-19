. "$PSScriptRoot\..\helpers\data_interface_files.ps1"

try {
    $filePath = "D:\Blaise5\Settings\catidb.bcdi"
    if (Test-Path $filePath)
    {
        Write-Host "$filePath already exists"  
    }
    else {
        #Create data interface
        CreateDataInterfaceFile -applicationType cati -filePath $filePath
        Write-Host "Created Cati Data Interface File"
    }
    
    #Get a list of all configuration settings for Blaise
    $configurationSettings = ListOfConfigurationSettings

    if ($configurationSettings.contains($filePath))
    {
        Write-Host "$filePath is already registered"
    }
    else {
        #register data interface
        RegisterCatiDataInterfaceFile -filePath $filePath
        restart-service blaiseservices5
        Write-Host "$filePath registered"
    }
}
catch {
    Write-Host "Error occured updated Cati database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
}

