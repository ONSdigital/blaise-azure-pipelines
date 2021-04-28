. "$PSScriptRoot\check_server_roles.ps1"

try {
    $applyRules = NodeHasTheCorrectRoles
    if (-not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Host "Updating node roles to: $roles"
        $output = C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
        Write-Host "Node roles updated $output"

        Write-Host "Restarting Blaise services"
        restart-service blaiseservices5 
        Write-Host "Blaise has been restarted"
    }
    else {
        Write-Host "Node has the correct roles"
    }
}
catch {
    Write-Host "Error updating blaise node roles. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}
