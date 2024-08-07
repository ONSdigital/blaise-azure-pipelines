. "$PSScriptRoot\..\logging_functions.ps1"

function CreateDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $applicationType
    )
    try {
        if (Test-Path $filePath) {
            LogInfo("Data interface file $filePath already exists")
            return $false
        }
        else {
            C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath
            LogInfo("Created $applicationType data interface file")
            return $true
        }
    }
    catch {
        LogError("Error occured creating $filePath data interface file")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

function RegisterDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $registerCommand
    )
    try {
        $configurationSettings = ListOfConfigurationSettings

        if ($configurationSettings.contains($filePath)) {
            LogInfo("Data interface file $filePath already registered")
            return $false
        }
        else {
            c:\blaise5\bin\servermanager -ecs -$($registerCommand):$filePath
            LogInfo("Data interface file $filePath registered")
            return $true
        }
    }
    catch {
        LogError("Error occured registering $filePath data interface file")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
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

        if ($xml.InnerXml.Contains($filePath)) {
            LogInfo("Data interface file $filePath already registered via XML")
            return $false
        }
        else {
            $xmlFragment = $xml.CreateDocumentFragment()
            $xmlFragment.InnerXml = $txtFragment
            $node = $xml.SelectSingleNode('//appSettings')
            $node.AppendChild($xmlFragment)

            $xml.Save($configFile)
            LogInfo("Data interface file $filePath registered via XML")
            return $true
        }
    }
    catch {
        LogError("Error occured registering $filePath data interface file via XML")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }

}

function ListOfConfigurationSettings {
    $configurationSettings = c:\blaise5\bin\servermanager -listconfigurationsettings | Out-String
    return $configurationSettings
}
