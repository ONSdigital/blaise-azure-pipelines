. "$PSScriptRoot\check_server_roles.ps1"

try {
    Write-Output "Running NodeHasTheCorrectRoles"
    $applyRules = NodeHasTheCorrectRoles
    Write-Output "applyRules - $applyRules"
    if (-not $applyRules)
    {
        $roles = RolesNodeShouldHave

        Write-Output "Updating node roles to: $roles"
        $output = C:\Blaise5\Bin\ServerManager -role:$roles | Out-String
        Write-Output "Node roles updated $output"

        Write-Output "Restarting Blaise service"
        restart-service blaiseservices5
        Write-Output "Blaise service has been restarted"
    }
    else {
        Write-Output "Node already has the correct roles"
    }
}
catch {
    Write-Output "Error updating blaise node roles. $($_.Exception.Message) at: $($_.ScriptStackTrace)"
    exit 1
}