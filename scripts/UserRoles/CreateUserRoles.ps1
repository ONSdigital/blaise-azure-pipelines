$userRolesUri = "$env:ENV_RESTAPI_URL/api/v1/users/roles"
$rolesJsonFile = "scripts/UserRoles/userroles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json 

foreach ($userRole in $userRoles)
{   
    $body = $userRole | ConvertTo-Json 

    Invoke-RestMethod -UseBasicParsing $userRolesUri -ContentType "application/json" -Method POST -Body $body
}
