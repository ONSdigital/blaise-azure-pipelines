. "$PSScriptRoot\..\..\logging_functions.ps1"
. "$PSScriptRoot\user_role_functions.ps1"

$rolesJsonFile = "$PSScriptRoot\user_roles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json

foreach ($userRole in $userRoles) {
    $exists = CheckUserRoleExists -userRoleName $userRole.name

    If ($exists -ne $true) {
        LogInfo("User role '$($userRole.name)' does not exist. Creating user role")
        CreateUserRole -userRole $userRole
        LogInfo("User role '$($userRole.name)' has been created")
        continue
    }

    $getUserRoleResponse = GetUserRole -userRoleName $userRole.name

    $roleEqual = ($getUserRoleResponse.permissions | ConvertTo-Json -Compress) -eq
                 ($userRole.permissions | ConvertTo-Json -Compress)

    If ($roleEqual -ne $true) {
        LogInfo("User role permissions do not match for the role '$($userRole.name)'")
        UpdateUserRole -userRole $userRole
        LogInfo("User role permissions have been updated for the role '$($userRole.name)'")
        continue
    }

    LogInfo("User role '$($userRole.name)' already exists")
}
