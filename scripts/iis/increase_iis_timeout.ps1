. "$PSScriptRoot\iis_timeout_functions.ps1"

try{
    setTimeoutValues
}
catch {
    Write-Host "Error checking/updating IIS timeouts. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}