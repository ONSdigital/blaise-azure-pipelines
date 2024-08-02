. "$PSScriptRoot\..\logging_functions.ps1"

function ConfigureServerpark {
    param(
        [string] $ManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME,
        [string] $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT,
        [string] $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD,
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

    LogInfo("Configuring server park $BlaiseServerPark to run in disconnected mode")

    c:\blaise5\bin\servermanager -editserverpark:$BlaiseServerPark -server:$managementNode -runmode:disconnected -syncsurveyswhenconnected:false -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword

    LogInfo("Configured server park $BlaiseServerPark")
}

try {
    ConfigureServerpark
}
catch {
    LogError("Configuring server park $BlaiseServerPark failed")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
