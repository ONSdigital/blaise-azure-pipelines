$userRolesBaseUri = "$env:ENV_RESTAPI_URL/api/v1/userroles"

function CheckUserRoleExists {
    param (
        [string] $restApiUrl = $userRolesBaseUri,
        [string] $userRoleName
    )

    $restApiUri = "$restApiUrl/$userRoleName/exists"

    return Invoke-RestMethod -UseBasicParsing $restApiUri -ContentType "application/json" -Method GET
}

function GetUserRole {
    param (
        [string] $restApiUrl = $userRolesBaseUri,
        [string] $userRoleName
    )
    
    $restApiUri = "$restApiUrl/$userRoleName"

    return Invoke-RestMethod -UseBasicParsing $restApiUri -ContentType "application/json" -Method GET
}

function CreateUserRole {
    param (
        [string] $restApiUrl = $userRolesBaseUri,
        [System.Object] $userRole
    )
    
    $body = $userRole | ConvertTo-Json 
    
    Invoke-RestMethod -UseBasicParsing $restApiUrl -ContentType "application/json" -Method POST -Body $body
}

function UpdateUserRole {
    param (
        [string] $restApiUrl = $userRolesBaseUri,
        [System.Object] $userRole
    )
    
    $body = ConvertTo-Json @($userRole.permissions)

    $restApiUri = "$restApiUrl/$($userRole.name)/permissions"

    Invoke-RestMethod -UseBasicParsing $restApiUri -ContentType "application/json" -Method PATCH -Body $body
}