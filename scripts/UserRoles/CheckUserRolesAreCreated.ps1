$userRolesUri = "$env:ENV_RESTAPI_URL/api/v1/userroles"
$rolesJsonFile = "scripts/UserRoles/userroles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json 

foreach ($userRole in $userRoles)
{   
    $exists =  Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)/exists" -ContentType "application/json" -Method GET
    
    If ($exists -ne $true) {
        throw [System.Exception] "$The user role '$($userRole.name)' was not found"
    }

    $response = Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)" -ContentType "application/json" -Method GET
    
    $roleEqual = ($response | ConvertTo-Json -Compress) -eq 
                 ($userRole | ConvertTo-Json -Compress)

    If ($roleEqual -ne $true) {
        throw [System.Exception] "$The user role '$($userRole.name)' was not configured as expected"
    }
}
