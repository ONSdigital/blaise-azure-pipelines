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
    return $rolesItShouldHave -join ','
}

function CurrentNodeRoles {
    return C:\Blaise5\Bin\ServerManager -lsr | Out-String
}

function ParseCurrentNodeRoles([Parameter(Mandatory=$False)]$CurrentRoles='') {
    if ([string]::IsNullOrEmpty($CurrentRoles))
    {
        $CurrentRoles = CurrentNodeRoles
    }
    $Roles = @()
    $CurrentRoles.Split('|').ForEach({
        $Role = $_.Trim()
        switch -regex ($Role)
        {
            '\bADMIN\b' { $Roles += 'admin' }
            '\bAUDITTRAIL\b' { $Roles += 'audittrail' }
            '\bCARI\b' { $Roles += 'cari' }
            '\bCATI\b' { $Roles += 'cati' }
            '\bCASEMANAGEMENT\b' { $Roles += 'casemanagement' }
            '\bDATA\b' { $Roles += 'data' }
            '\bDATAENTRY\b' { $Roles += 'dataentry' }
            '\bDASHBOARD\b' { $Roles += 'dashboard' }
            '\bEVENT\b' { $Roles += 'event' }
            '\bPUBLISH\b' { $Roles += 'publish' }
            '\bRESOURCE\b' { $Roles += 'resource' }
            '\bSESSION\b' { $Roles += 'session' }
            '\bWEB\b' { $Roles += 'web' }
        }
    })
    $Roles = $Roles | Sort-Object
    return $Roles -join ','
}

function CheckNodeHasCorrectRoles {
    param (
        [string] $CurrentNodeRoles,
        [string] $RolesNodeShouldHave
    )
    return $CurrentNodeRoles -eq $RolesNodeShouldHave
}