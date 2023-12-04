function ConfigureCmaServerpark{
    param(
        [string] $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME,
        [string] $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT,
        [string] $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD,
        [string] $BlaiseCmaServerPark = $env:ENV_BLAISE_CMA_SERVER_PARK_NAME,
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

    If ([string]::IsNullOrEmpty($BlaiseCmaServerPark)) {
        throw [System.IO.ArgumentException] "No Blaise CMA server park argument provided"
    }

    If ([string]::IsNullOrEmpty($BlaiseUserName)) {
        throw [System.IO.ArgumentException] "No Blaise username argument provided"
    }

    Write-Host "Add and configure CMA server park to run in disconnected mode"

    c:\blaise5\bin\servermanager -addserverpark:$BlaiseCmaServerPark -runmode:disconnected -server:$managementNode -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword

    Write-Host "Configured CMA server park to run in disconnected mode"
}

try{
    ConfigureCmaServerpark
}
catch{
    Write-Host "Adding and/or configuring CMA server park to run in disconnected mode failed: $($_.ScriptStackTrace)"
    exit 1
}
