function RegisterNode{
    param(
        [string] $CurrentNode = $(hostname),
        [string] $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME,
        [string] $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT,
        [SecureString] $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD,
        [string] $BlaiseServerPark = $env:ENV_BLAISE_SERVER_PARK_NAME,
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

    If ([string]::IsNullOrEmpty($BlaiseServerPark)) {
        throw [System.IO.ArgumentException] "No Blaise server park argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaiseUserName)) {
        throw [System.IO.ArgumentException] "No Blaise username argument provided"
    }

    Write-Information "Registering $currentNode on management node $managementNode"

    c:\blaise5\bin\servermanager -addserverparkserver:$currentNode -server:$managementNode -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword -serverpark:$blaiseServerPark -serverport:$connectionPort -serverbinding:http -masterhostname:$managementNode -logicalroot:default -server:$managementNode -binding:http -port:$connectionPort

    Write-Information "$currentNode registered"
}

try{
    RegisterNode
}
catch{
    Write-Information "Nodes have not been registered: $($_.ScriptStackTrace)"
    exit 1
}
