. "$PSScriptRoot\check_server_roles.ps1"

try {
    $applyRules = NodeHasTheCorrectRoles
    if (-not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Host "Updating node roles to: $roles"
        c:\blaise5\bin\servermanager -role:$roles
        Write-Host "Node roles updated"

        Write-Host "Restarting Blaise services"
        restart-service blaiseservices5 
        Write-Host "Blaise has been restarted"
    }
    else {
        Write-Host "Node has the correct roles"
    }
}
catch {
    Write-Host "Error updating blaise node roles. $($_.ScriptStackTrace)"
    exit 1
}
