. "$PSScriptRoot\user_role_functions.ps1"

$rolesJsonFile = "$PSScriptRoot\user_roles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json

foreach ($userRole in $userRoles)
{
    $exists = CheckUserRoleExists -userRoleName $userRole.name

    If ($exists -ne $true) {
        throw [System.Exception] "$The user role '$($userRole.name)' was not found"
    }

    $getUserRoleResponse = GetUserRole -userRoleName $userRole.name

    $roleEqual = ($getUserRoleResponse | ConvertTo-Json -Compress) -eq
                 ($userRole | ConvertTo-Json -Compress)

    If ($roleEqual -ne $true) {
        throw [System.Exception] "$The user role '$($userRole.name)' was not configured as expected"
    }
}
