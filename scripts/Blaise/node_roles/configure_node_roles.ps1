. "$PSScriptRoot\node_role_functions.ps1"

try {
    $hasCorrectRoles = Check-NodeHasCorrectRoles
    if (-not $hasCorrectRoles) {
        $roles = Get-RequiredRoles
        if ($null -eq $roles) {
            throw "Failed to retrieve required roles."
        }

        Write-Host "Updating node roles to: $roles"
        try {
            $output = & C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
            Write-Host "Node roles updated: $output"
        }
        catch {
            throw "Failed to update node roles: $_"
        }

        Write-Host "Restarting Blaise service"
        try {
            Restart-Service -Name BlaiseServices5 -ErrorAction Stop
            Write-Host "Blaise service has been restarted"
        }
        catch {
            throw "Failed to restart Blaise service: $_"
        }
    }
    else {
        Write-Host "Node already has the correct roles"
    }
}
catch {
    Write-Error "Error updating Blaise node roles: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}