function CreateDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $applicationType
    )
    try {
        #$filePath = "D:\Blaise5\Settings\catidb.bcdi"
        if (Test-Path $filePath)
        {
            Write-Output "$filePath already exists"
        }
        else {
            #Create data interface
            C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath

            Write-Output "Created $applicationType Data Interface File"
        }
    }
    catch {
        Write-Output "Error occured Creating $filePath data interface: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
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
            Write-Output "$filePath is already registered"
        }
        else {
            #register data interface
            c:\blaise5\bin\servermanager -ecs -$($registerCommand):$filePath

            Write-Output "$filePath registered"
        }
    }
    catch {
        Write-Output "Error occured updating $filePath database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
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
            Write-Output "$filePath database is already set"
        }
        else
        {
            $xmlFragment = $xml.CreateDocumentFragment()
            $xmlFragment.InnerXml = $txtFragment
            $node = $xml.SelectSingleNode('//appSettings')
            $node.AppendChild($xmlFragment)

            $xml.Save($configFile)
            Write-Output "$filePath database has been set"
        }
    }
    catch{
        Write-Output "Error occured updating $filePath database to mysql: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
        exit 1
    }

}

function ListOfConfigurationSettings {
    $configurationSettings = c:\blaise5\bin\servermanager -listconfigurationsettings | Out-String
    return $configurationSettings
}

