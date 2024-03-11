function CheckFileExists {
    param(
        [string] $filePath
    )

    if (Test-Path $filePath)
        {
            return
        }

    Write-Host "File $filePath does not exist"
    exit 1        
}

function InstallPackageViaServerManager{
    param(
        [string] $ServerParkName,
        [string] $filePath,
        [string] $ConnectionPort,
        [string] $BlaiseUserName,
        [string] $BlaisePassword        
    )

    CheckFileExists($filePath)

    try {
        "Iinstalling the package $filePath into the serverpark $ServerParkName"
        c:\blaise5\bin\servermanager -installsurvey:$filePath -serverpark:cma -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword
    }
    catch {
        Write-Host "There was an error installing the package $filePath into the serverpark $ServerParkName"
        exit 1  
    }     
}

function InstallPackageViaBlaiseCli{
    param(
        [string] $ServerParkName,
        [string] $filePath,
        [string] $ConnectionPort,
        [string] $BlaiseUserName,
        [string] $BlaisePassword        
    )

    CheckFileExists($filePath)
}

function UnzipPackage {
    param(
        [string] $filePath,
        [string] $destinationPath
    )  

    CheckFileExists($filePath)

    try {
        "Exapnding zip file $filePath to $destinationPath"
        Expand-Archive -LiteralPath $filePath -DestinationPath $destinationPath
    }
    catch {
        Write-Host "There was an error exapnding zip file $filePath to $destinationPath"
        exit 1  
    }
}


try{
    $cmaInstrumentPath = "$env:InstrumentPath\cma"
    $BlaiseCmaServerPark = $env:CmaServerParkName
    $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT
    $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD
    $BlaiseUserName = $env:ENV_BLAISE_ADMIN_USER    

    # Extract cma packages from multipackage file
    Write-Host "unzip cma multi package"
    UnzipPackage -filePath $env:InstrumentPath\CMA.zip -destinationPath $cmaInstrumentPath

    # Install cma package via servermanager (as it does not contain a database)
    Write-Host "Install cma package via servermanager"
    InstallPackageViaServerManager -ServerParkName $BlaiseCmaServerPark -filePath $cmaInstrumentPath\CMA.bpkg -ConnectionPort:$ConnectionPort -BlaiseUserName:$BlaiseUserName -BlaisePassword:$BlaisePassword
}
catch{
    Write-Host "Installing cma packages failed: $($_.ScriptStackTrace)"
    exit 1
}



