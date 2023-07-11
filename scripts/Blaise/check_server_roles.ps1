function NodeHasTheCorrectRoles {
    $requiredRoles = RolesNodeShouldHave
    Write-Host "Required roles: $requiredRoles"
    $currentRoles = ParseCurrentNodeRoles
    Write-Host "Current roles: $currentRoles"
    return CheckNodeHasCorrectRoles -CurrentNodeRoles $currentRoles -RolesNodeShouldHave $requiredRoles
}
function RolesNodeShouldHave {
    $role_server_should_Have = [Environment]::GetEnvironmentVariable('ENV_BLAISE_ROLES', 'Machine')
    $rolesItShouldHave = $role_server_should_Have.Split(',').Trim() | Sort-Object
    Write-Host "Node should have these roles after sorting: $rolesItShouldHave"
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
        '\bDATA\b' { $roles += 'data,' }
        'RESOURCE' { $roles += 'resource,' }
        'DATAENTRY' { $roles += 'dataentry,' }
        'DASHBOARD' { $roles += 'dashboard' }
    }

    $roles = $roles.Split(',').Trim() | Sort-Object
    Write-Host "Node currently has these roles after sorting: $roles"
    return $roles -join ','
}

function CheckNodeHasCorrectRoles {
    param (
        [string] $CurrentNodeRoles,
        [string] $RolesNodeShouldHave
    )
    return $CurrentNodeRoles -eq $RolesNodeShouldHave
}
