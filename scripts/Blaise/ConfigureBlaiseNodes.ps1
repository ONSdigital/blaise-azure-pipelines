$ServerRoles = $env:ENV_BLAISE_SERVER_ROLES.ToUpper()

[Collections.Generic.List[String]]$ListOfServerRoles = $ServerRoles.Split(',')

$RESTAPI_URL = "$env:ENV_RESTAPI_URL/api/v1/serverparks/$env:ServerParkName/server"

$hostname = hostname

$JsonObject = [ordered]@{
    name = "$hostname"
    logicalServerName = "Default"
    roles = @($ListOfServerRoles)
  }

$body = $JsonObject | ConvertTo-Json

Write-Host $body

Invoke-RestMethod -UseBasicParsing $RESTAPI_URL -ContentType "application/json" -Method POST -Body $body
