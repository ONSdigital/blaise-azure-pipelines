function CreateDataInterfaceFile {
    param (
        [string] $filePath,
        [string] $applicationType
    )
    try {
        if (Test-Path $filePath)
        {
            Write-Host "Data interface file $filePath already exists"
            return $false
        }
        else {
            C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath
            Write-Host "Created $applicationType data interface file"
            return $true
        }
    }
    catch {
        Write-Host "Error occured creating $filePath data interface file: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
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

        if ($configurationSettings.contains($filePath))
        {
            Write-Host "Data interface file $filePath already registered"
            return $false
        }
        else {
            c:\blaise5\bin\servermanager -ecs -$($registerCommand):$filePath
            Write-Host "Data interface file $filePath registered"
            return $true
        }
    }
    catch {
        Write-Host "Error occured registering $filePath data interface file: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
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
            Write-Host "$filePath data interface xml file already registered"
            return $false
        }
        else
        {
            $xmlFragment = $xml.CreateDocumentFragment()
            $xmlFragment.InnerXml = $txtFragment
            $node = $xml.SelectSingleNode('//appSettings')
            $node.AppendChild($xmlFragment)

            $xml.Save($configFile)
            Write-Host "$filePath data interface xml file registered"
            return $true
        }
    }
    catch{
        Write-Host "Error occured registering $filePath data interface xml file: $($_.Exception.Message) at: $($_.ScriptStackTrace)"
        exit 1
    }

}

function ListOfConfigurationSettings {
    $configurationSettings = c:\blaise5\bin\servermanager -listconfigurationsettings | Out-String
    return $configurationSettings
}
