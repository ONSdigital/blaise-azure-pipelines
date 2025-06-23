. "$PSScriptRoot\..\..\logging_functions.ps1"
. "$PSScriptRoot\node_role_functions.ps1"

try {
    $hasCorrectRoles = Check-NodeHasCorrectRoles
    if (-not $hasCorrectRoles) {
        $roles = Get-RequiredRoles
        if ($null -eq $roles) {
            throw "Failed to retrieve required roles"
        }

        LogInfo("Updating node roles to: $roles")
        try {
            $output = & C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
            LogInfo("Node roles updated: $output")
        }
        catch {
            throw "Failed to update node roles: $_"
        }

        LogInfo("Restarting Blaise service")
        $maxRetries = 3
        $delay = 5  # Initial delay in seconds
        $attempt = 0
        $serviceRestarted = $false
        while ($attempt -lt $maxRetries -and -not $serviceRestarted) {
            try {
                Restart-Service -Name BlaiseServices5 -ErrorAction Stop
                LogInfo("Blaise service has been restarted")
                $serviceRestarted = $true
            }
            catch {
                $attempt++
                if ($attempt -lt $maxRetries) {
                    LogWarning("Attempt $attempt to restart Blaise service failed. Retrying in ${delay}s...")
                    Start-Sleep -Seconds $delay
                    $delay *= 2
                }
                else {
                    throw "Failed to restart Blaise service after $maxRetries attempts: $_"
                }
            }
        }
    }
    else {
        LogInfo("Node already has the correct roles")
    }
}
catch {
    LogError("Error updating Blaise node roles")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
