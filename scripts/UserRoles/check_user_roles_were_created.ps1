. "$PSScriptRoot\..\functions\LoggingFunctions.ps1"
. "$PSScriptRoot\..\functions\UserRoleFunctions.ps1"

$rolesJsonFile = "scripts/UserRoles/userroles.json"

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
