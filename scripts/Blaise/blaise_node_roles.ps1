. "$PSScriptRoot\check_server_roles.ps1"

try {
    $applyRules = NodeHasTheCorrectRoles
    if (-not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Output "Updating node roles to: $roles"
        $output = C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
        Write-Output "Node roles updated $output"

        Write-Output "Restarting Blaise services"
        restart-service blaiseservices5
        Write-Output "Blaise has been restarted"
    }
    else {
        Write-Output "Node has the correct roles"
    }
}
catch {
    Write-Output "Error updating blaise node roles. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}