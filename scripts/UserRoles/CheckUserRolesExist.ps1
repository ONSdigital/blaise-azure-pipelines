$userRolesUri = "$env:ENV_RESTAPI_URL/api/v1/userroles"
$rolesJsonFile = "scripts/UserRoles/userroles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json 

foreach ($userRole in $userRoles)
{   
    $exists =  Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)/exists" -ContentType "application/json" -Method GET
    
    If ($exists -ne $true) {
        Write-Host "User roles does not exist. Creating user roles"
        Invoke-Expression "$currentPath\scripts\UserRoles\CreateUserRoles.ps1"
        exit
    }

    $response = Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)" -ContentType "application/json" -Method GET
    
    $roleEqual = ($response | ConvertTo-Json -Compress) -eq 
                 ($userRole | ConvertTo-Json -Compress)

    If ($roleEqual -ne $true) {
        Write-Host "User role permissions do not exist. Creating user role permissons"
        Invoke-Expression "$currentPath\scripts\UserRoles\CreateUserRoles.ps1"
        exit
    }
}
Write-Host "User roles already exist"
