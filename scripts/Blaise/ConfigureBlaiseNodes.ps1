$ServerRoles = $env:ENV_BLAISE_SERVER_ROLES.ToUpper()

[Collections.Generic.List[String]]$ListOfServerRoles = $ServerRoles.Split(',')

$RESTAPI_URL = "http://$env:ENV_RESTAPI_URL/api/v1/serverparks/$env:ServerParkName/server"

$InternalComputerName = hostname

$JsonObject = [ordered]@{
    name = "$InternalComputerName"
    logicalServerName = "Default"
    roles = @($ListOfServerRoles)
  }

$body = $JsonObject | ConvertTo-Json

Write-Host $body

Invoke-RestMethod -UseBasicParsing $RESTAPI_URL -ContentType "application/json" -Method POST -Body $body
