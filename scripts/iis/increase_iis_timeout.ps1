. "$PSScriptRoot\..\logging_functions.ps1"
. "$PSScriptRoot\iis_timeout_functions.ps1"

try {
    setTimeoutValues
}
catch {
    LogError("Error checking/updating IIS timeouts")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
