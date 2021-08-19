function CreateDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $applicationType
    )
    try {
        #$filePath = "D:\Blaise5\Settings\catidb.bcdi"
        if (Test-Path $filePath)
        {
            Write-Host "$filePath already exists"  
        }
        else {
            #Create data interface
            C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath
            Write-Host "Created $applicationType Data Interface File"
        }
    }
    catch {
        Write-Host "Error occured Creating $filePath data interface: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
        exit 1
    }
}

function RegisterDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $registerCommand
    )
    try {
        #Get a list of all configuration settings for Blaise
        $configurationSettings = ListOfConfigurationSettings
    
        if ($configurationSettings.contains($filePath))
        {
            Write-Host "$filePath is already registered"
        }
        else {
            #register data interface
            c:\blaise5\bin\servermanager -ecs -$($registerCommand):$filePath
            Write-Host "$filePath registered"
        }
    }
    catch {
        Write-Host "Error occured updating $filePath database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
        exit 1
    }
}

function RegisterDatainterfaceViaXML {
    param (
        [string] $filePath,
        [string] $configFile,
        [string] $interfaceFileName
    )
    try {
        $xml = [xml](Get-Content $configFile)

        $txtFragment = @"
        <add key="$interfaceFileName" value="$filePath"/>
"@
    
        if($xml.InnerXml.Contains($filePath)){
            Write-Host "$filePath database is already set"
        }
        else
        {
            $xmlFragment = $xml.CreateDocumentFragment()
            $xmlFragment.InnerXml = $txtFragment
            $node = $xml.SelectSingleNode('//appSettings')
            $node.AppendChild($value)
    
            $xml.Save($configFile)
            Write-Host "$filePath database has been set"
        }
    }
    catch{
        Write-Host "Error occured updating $filePath database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
        exit 1
    }
    
}

function ListOfConfigurationSettings {
    $configurationSettings = c:\blaise5\bin\servermanager -listconfigurationsettings | Out-String
    return $configurationSettings
}

