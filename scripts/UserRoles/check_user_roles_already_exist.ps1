$userRolesUri = "$env:ENV_RESTAPI_URL/api/v1/userroles"
$rolesJsonFile = "scripts/UserRoles/userroles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json 

foreach ($userRole in $userRoles)
{   
    $exists =  Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)/exists" -ContentType "application/json" -Method GET
    
    If ($exists -ne $true) {
        Write-Host "##vso[task.setvariable variable=UserRolesExist;isOutput=true]False"
        exit 
    }

    $response = Invoke-RestMethod -UseBasicParsing "$($userRolesUri)/$($userRole.name)" -ContentType "application/json" -Method GET
    
    $roleEqual = ($response | ConvertTo-Json -Compress) -eq 
                 ($userRole | ConvertTo-Json -Compress)

    If ($roleEqual -ne $true) {
        Write-Host "##vso[task.setvariable variable=UserRolesExist;isOutput=true]False"
        exit
    }
}
Write-Host "##vso[task.setvariable variable=UserRolesExist;isOutput=true]True"
