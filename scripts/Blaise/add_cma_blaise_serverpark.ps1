function ConfigureCmaServerpark{
    param(
        [string] $ServerParkName,
        [string] $ManagementNode,
        [string] $ConnectionPort,
        [string] $BlaiseUserName,
        [string] $BlaisePassword
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

    Write-Host "Add and/or configure server park '$ServerParkName' to run in disconnected mode with sync surveys set to true"

    #if the serverpark exists this will update the existing one
    c:\blaise5\bin\servermanager -addserverpark:$ServerParkName -runmode:disconnected -server:$managementNode -syncsurveyswhenconnected:true -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword

    Write-Host "Configured server park '$ServerParkName'"
}

try{
    $BlaiseCmaServerPark = $env:CmaServerParkName
    Write-Host "server park - $($BlaiseCmaServerPark)"
    $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME
    Write-Host "server - $($ManagementNode)"
    $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT
    Write-Host "port - $($ConnectionPort)"
    $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD
    $BlaiseUserName = $env:ENV_BLAISE_ADMIN_USER

    ConfigureCmaServerpark -ServerParkName:$BlaiseCmaServerPark -ManagementNode:$ManagementNode -ConnectionPort:$ConnectionPort -BlaiseUserName:$BlaiseUserName -BlaisePassword:$BlaisePassword
    ConfigureCmaServerpark -ServerParkName:"$($BlaiseCmaServerPark)_app" -ManagementNode:$ManagementNode -ConnectionPort:$ConnectionPort -BlaiseUserName:$BlaiseUserName -BlaisePassword:$BlaisePassword 
    ConfigureCmaServerpark -ServerParkName:"$($BlaiseCmaServerPark)_admin" -ManagementNode:$ManagementNode -ConnectionPort:$ConnectionPort -BlaiseUserName:$BlaiseUserName -BlaisePassword:$BlaisePassword 
}
catch{
    Write-Host "Adding and/or configuring CMA server parks failed: $($_.ScriptStackTrace)"
    exit 1
}
