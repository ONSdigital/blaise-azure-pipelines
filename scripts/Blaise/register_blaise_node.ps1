function RegisterNode{
    param(
        [string] $ServerPark,
        [string] $CurrentNode = $(hostname),
        [string] $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME,
        [string] $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT,
        [string] $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD,
        [string] $BlaiseUserName = $env:ENV_BLAISE_ADMIN_USER
    )

    If ([string]::IsNullOrEmpty($ManagementNode)) {
        throw [System.IO.ArgumentException] "No management node argument provided"
    }

    If ([string]::IsNullOrEmpty($ConnectionPort)) {
        throw [System.IO.ArgumentException] "No Blaise connection port argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaisePassword)) {
        throw [System.IO.ArgumentException] "No Blaise Admin Password argument provided"
    }

    If ([string]::IsNullOrEmpty($ServerPark)) {
        throw [System.IO.ArgumentException] "No Blaise server park argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaiseUserName)) {
        throw [System.IO.ArgumentException] "No Blaise username argument provided"
    }

    Write-Host "Registering $currentNode on management node $managementNode"


    c:\blaise5\bin\servermanager -addserverparkserver:$currentNode -server:$managementNode -user:$blaiseUserName -password:$blaisePassword -serverpark:$ServerPark -serverport:$connectionPort -serverbinding:http -masterhostname:$managementNode -logicalroot:default -binding:http -port:$connectionPort

    Write-Host "$currentNode registered"
}

try{
    # reguster for gusty
    RegisterNode -ServerPark:$env:ENV_BLAISE_SERVER_PARK_NAME

    #register for cma
    RegisterNode -ServerPark:$env:CmaServerParkName
}
catch{
    Write-Host "Nodes have not been registered: $($_.ScriptStackTrace)"
    exit 1
}
