$userRolesUri = "$($env:BASE_URI_VAR)/roles/user"
$rolesJsonFile = "userroles.json"

$userRoles = Get-Content -Raw -Path $rolesJsonFile | ConvertFrom-Json 

foreach ($userRole in $userRoles)
{   
    $body = $userRole | ConvertTo-Json 

    Invoke-RestMethod -UseBasicParsing $userRolesUri -ContentType "application/json" -Method POST -Body $body
}
