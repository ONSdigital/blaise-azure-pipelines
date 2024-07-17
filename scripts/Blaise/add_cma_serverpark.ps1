. "$PSScriptRoot\..\logging_functions.ps1"

function ServerParkExists {
    param(
        [string] $ServerParkName
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name argument provided"
    }

    $exists = c:\blaise5\bin\servermanager -listserverparks `
                                         -server:$env:ENV_BLAISE_SERVER_HOST_NAME `
                                         -binding:http `
                                         -port:$env:ENV_BLAISE_CONNECTION_PORT `
                                         -user:$env:ENV_BLAISE_ADMIN_USER `
                                         -password:$env:ENV_BLAISE_ADMIN_PASSWORD `
                                        | findstr -i "cma"                                        
        
    If ([string]::IsNullOrEmpty($exists)) {
        return $false
    }

    return $true
}
function AddServerPark{
    param(
        [string] $ServerParkName
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name argument provided"
    }

    LogInfo("Add and/or configure server park $ServerParkName to run in disconnected mode with sync surveys set to true")

    # if the serverpark exists this will update the existing one
    c:\blaise5\bin\servermanager -addserverpark:$ServerParkName `
                                 -runmode:disconnected `
                                 -server:$env:ENV_BLAISE_SERVER_HOST_NAME `
                                 -syncsurveyswhenconnected:true `
                                 -binding:http `
                                 -port:$env:ENV_BLAISE_CONNECTION_PORT `
                                 -user:$env:ENV_BLAISE_ADMIN_USER `
                                 -password:$env:ENV_BLAISE_ADMIN_PASSWORD

    LogInfo("Configured server park $ServerParkName")
}

try{
    if(ServerParkExists -ServerParkName:$env:CmaServerParkName) {
        LogInfo("Server park $env:CmaServerParkName already exists")
    }
    else {
        LogInfo("Adding and/or configuring server park $env:CmaServerParkName")
        AddServerPark -ServerParkName:$env:CmaServerParkName
    }
    
    exit 0
}
catch{
    LogError("Adding and/or configuring server park $env:CmaServerParkName failed")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
