function NodeHasTheCorrectRoles {
    $requiredRoles = RolesNodeShouldHave
    $currentRoles = ParseCurrentNodeRoles
    return CheckNodeHasCorrectRoles -CurrentNodeRoles $currentRoles -RolesNodeShouldHave $requiredRoles
}
function RolesNodeShouldHave {
    $role_server_should_Have = [Environment]::GetEnvironmentVariable('ENV_BLAISE_ROLES', 'Machine')
    $rolesItShouldHave = $role_server_should_Have.Trim().Split(',') | Sort-Object
    Write-Host "Node should have these roles after sorting: $role_server_should_Have"
    return $rolesItShouldHave -join ','
}

function CurrentNodeRoles {
    return C:\Blaise5\Bin\ServerManager -lsr | Out-String
}

function ParseCurrentNodeRoles {
    param (
        [string] $CurrentRoles
    )
    if ([string]::IsNullOrEmpty($CurrentRoles))
    {
        $CurrentRoles = CurrentNodeRoles
    }
    $roles = ""

    Switch -regex ($CurrentRoles)
    {
        'ADMIN' { $roles += 'admin,' }
        'CATI' { $roles += 'cati,' }
        'AUDITTRAIL' { $roles += 'audittrail,' }
        'WEB' { $roles += 'web,' }
        'SESSION' { $roles += 'session,' }
        'DATA' { $roles += 'data,' }
        'RESOURCE' { $roles += 'resource,' }
        'DATAENTRY' { $roles += 'dataentry,' }
        'DASHBOARD' { $roles += 'dashboard' }
    }

    $roles = $roles.Trim().Split(',') | Sort-Object
    Write-Host "Node currently has these roles after sorting: $role_server_should_Have"
    return $roles -join ','
}

function CheckNodeHasCorrectRoles {
    param (
        [string] $CurrentNodeRoles,
        [string] $RolesNodeShouldHave
    )
    return $CurrentNodeRoles -eq $RolesNodeShouldHave
}
