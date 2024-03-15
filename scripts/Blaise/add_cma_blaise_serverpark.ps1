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
function AddServerpark{
    param(
        [string] $ServerParkName
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name argument provided"
    }

    Write-Host "Add and/or configure server park '$ServerParkName' to run in disconnected mode with sync surveys set to true"

    #if the serverpark exists this will update the existing one
    c:\blaise5\bin\servermanager -addserverpark:$ServerParkName `
                                 -runmode:disconnected `
                                 -server:$env:ENV_BLAISE_SERVER_HOST_NAME `
                                 -syncsurveyswhenconnected:true `
                                 -binding:http `
                                 -port:$env:ENV_BLAISE_CONNECTION_PORT `
                                 -user:$env:ENV_BLAISE_ADMIN_USER `
                                 -password:$env:ENV_BLAISE_ADMIN_PASSWORD

    Write-Host "Configured server park '$ServerParkName'"
}

try{
    if(ServerParkExists -ServerParkName:$env:CmaServerParkName) {
        Write-Host "Serverpark $env:CmaServerParkName already exists"
    }
    else {
        Write-Host "Adding and/or configuring CMA server park $env:CmaServerParkName"
        AddServerpark -ServerParkName:$env:CmaServerParkName
    }
}
catch{
    Write-Host "Adding and/or configuring CMA server park $env:CmaServerParkName failed: $($_.ScriptStackTrace)"
    exit 1
}
