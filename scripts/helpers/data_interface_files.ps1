function CreateAndRegisterDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $applicationType,
        [string] $registerCommand
    )
    try {
        #$filePath = "D:\Blaise5\Settings\catidb.bcdi"
        if (Test-Path $filePath)
        {
            Write-Host "$filePath already exists"  
        }
        else {
            #Create data interface
            CreateDataInterfaceFile -applicationType $applicationType -filePath $filePath
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
            RegisterDataInterfaceFile -registerCommand $registerCommand -filePath $filePath
            Write-Host "$filePath registered"
        }
    }
    catch {
        Write-Host "Error occured updating $filePath database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    }
}

function CreateDataInterfaceFile {
    param (
        [string] $applicationType, 
        [string] $filePath
    )
    C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath
}

function RegisterDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $registerCommand
    )
    c:\blaise5\bin\servermanager -ecs -$($registerCommand):$filePath
}

function ListOfConfigurationSettings {
    $configurationSettings = c:\blaise5\bin\servermanager -listconfigurationsettings | Out-String
    return $configurationSettings
}

