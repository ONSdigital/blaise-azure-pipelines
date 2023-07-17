. "$PSScriptRoot\check_server_roles.ps1"

try {
    $applyRules = NodeHasTheCorrectRoles
    if (-Not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Information "Updating node roles to: $roles"
        $output = C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
        Write-Information "Node roles updated $output"

        Write-Information "Restarting Blaise service"
        restart-service blaiseservices5
        Write-Information "Blaise service has been restarted"
    }
    else {
        Write-Information "Node already has the correct roles"
    }
}
catch {
    Write-Information "Error updating blaise node roles. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}