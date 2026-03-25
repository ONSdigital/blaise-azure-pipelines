param (
    [string]$ConfigFilePath = "C:\Blaise5\Bin\StatNeth.Blaise.Runtime.ServicesHost.exe.config",
    [string]$ServiceName = "blaiseservices5"
)

. "$PSScriptRoot\..\logging_functions.ps1"

function Ensure-GCServerEnabled {
    param (
        [string]$ConfigFilePath
    )
    try {
        [xml]$xml = Get-Content $ConfigFilePath
        $runtimeNode = $xml.configuration.runtime
        if (-not $runtimeNode) {
            LogError("No <runtime> section found in $ConfigFilePath")
            return $false
        }
        $gcServerNode = $runtimeNode.gcServer
        if ($gcServerNode) {
            # Already present, check if enabled is true
            if ($gcServerNode.enabled -eq "true") {
                LogInfo("<gcServer enabled=\"true\"/> already present in $ConfigFilePath")
                return $false
            } else {
                $gcServerNode.enabled = "true"
                $xml.Save($ConfigFilePath)
                LogInfo("Updated <gcServer> to enabled=\"true\" in $ConfigFilePath")
                return $true
            }
        } else {
            # Not present, add it
            $gcServerElem = $xml.CreateElement("gcServer")
            $gcServerElem.SetAttribute("enabled", "true")
            $runtimeNode.AppendChild($gcServerElem) | Out-Null
            $xml.Save($ConfigFilePath)
            LogInfo("Added <gcServer enabled=\"true\"/> to $ConfigFilePath")
            return $true
        }
    } catch {
        LogError("Error updating <gcServer> in $ConfigFilePath")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
}

$changed = Ensure-GCServerEnabled -ConfigFilePath $ConfigFilePath
if ($changed) {
    LogInfo("Restarting $ServiceName due to gcServer config change...")
    restart-service $ServiceName
}
