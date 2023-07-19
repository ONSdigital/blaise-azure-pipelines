. "$PSScriptRoot\check_server_roles.ps1"

try {
    $applyRules = NodeHasTheCorrectRoles
    if (-Not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Host "Updating node roles to: $roles"
        $output = C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
        Write-Host "Node roles updated $output"

        Write-Host "Restarting Blaise service"
        restart-service blaiseservices5
        Write-Host "Blaise service has been restarted"
    }
    else {
        Write-Host "Node already has the correct roles"
    }
}
catch {
    Write-Host "Error updating blaise node roles. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}