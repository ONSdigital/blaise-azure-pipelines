function ConfigureCmaServerpark{
    param(
        [string] $ServerParkName,
        [string] $ManagementNode,
        [string] $ConnectionPort,
        [string] $BlaiseUserName,
        [string] $BlaisePassword,
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name argument provided"
    }

    If ([string]::IsNullOrEmpty($ManagementNode)) {
        throw [System.IO.ArgumentException] "No management node argument provided"
    }

    If ([string]::IsNullOrEmpty($ConnectionPort)) {
        throw [System.IO.ArgumentException] "No Blaise connection port argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaiseUserName)) {
        throw [System.IO.ArgumentException] "No Blaise username argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaisePassword)) {
        throw [System.IO.ArgumentException] "No Blaise Admin Password argument provided"
    }

    Write-Host "Add and/or configure server park '$ServerParkName'"

    #if the serverpark exists this will update the existing one
    c:\blaise5\bin\servermanager -addserverpark:$ServerParkName -runmode:disconnected -server:$managementNode -syncsurveyswhenconnected:true -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword

    Write-Host "Configured server park '$ServerParkName'"
}

try{
    $BlaiseCmaServerPark = $env:ENV_BLAISE_CMA_SERVER_PARK_NAME,
    $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME,
    $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT,
    $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD,
    $BlaiseUserName = $env:ENV_BLAISE_ADMIN_USER

    ConfigureCmaServerpark($BlaiseCmaServerPark, $ManagementNode, $ConnectionPort, $BlaiseUserName, $BlaisePassword)
    ConfigureCmaServerpark($BlaiseCmaServerPark + "_APP", $ManagementNode, $ConnectionPort, $BlaiseUserName, $BlaisePassword)
    ConfigureCmaServerpark($BlaiseCmaServerPark + "_ADMIN", $ManagementNode, $ConnectionPort, $BlaiseUserName, $BlaisePassword)
}
catch{
    Write-Host "Adding and/or configuring CMA server parks failed: $($_.ScriptStackTrace)"
    exit 1
}
