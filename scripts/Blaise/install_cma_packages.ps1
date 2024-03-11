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
        c:\blaise5\bin\servermanager -installsurvey:$filePath -serverpark:$ServerParkName -binding:http -port:$connectionPort -user:$blaiseUserName -password:$blaisePassword
    }
    catch {
        Write-Host "There was an error installing the package $filePath into the serverpark $ServerParkName"
        exit 1  
    }     
}

function InstallPackageViaBlaiseCli{
    param(
        [string] $ServerParkName,
        [string] $filePath
    )

    #CheckFileExists($filePath)
    try {
        "Iinstalling the package $filePath into the serverpark $ServerParkName"
        C:\BlaiseServices\BlaiseCli\blaise.cli -s $ServerParkName -f $filePath
       
    }
    catch {
        Write-Host "There was an error installing the package $filePath into the serverpark $ServerParkName"
        exit 1  
    }      
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
    # Configure variables
    $BlaiseServerPark = $env:ENV_BLAISE_SERVER_PARK_NAME,
    $ConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT
    $BlaisePassword = $env:ENV_BLAISE_ADMIN_PASSWORD
    $BlaiseUserName = $env:ENV_BLAISE_ADMIN_USER    
    $cmaInstrumentPath = "$env:InstrumentPath\CMA"
    $BlaiseCmaServerPark = $env:CmaServerParkName

    # Extract cma packages from multipackage file
    Write-Host "unzip cma multi package"
    UnzipPackage -filePath $env:InstrumentPath\CMA.zip -destinationPath $cmaInstrumentPath

    # Install cma package via servermanager (as it does not contain a database)
    Write-Host "Install cma package via servermanager"
    InstallPackageViaServerManager -ServerParkName $BlaiseCmaServerPark -filePath $cmaInstrumentPath\CMA.bpkg -ConnectionPort:$ConnectionPort -BlaiseUserName:$BlaiseUserName -BlaisePassword:$BlaisePassword

    # Install other packages via Bliase CLI to configure the datbaases to be cloud based
    $InstrumentPackageList = 'CMA_Attempts.bpkg', 'CMA_ContactInfo.bpkg', 'CMA_Launcher.bpkg', 'CMA_Logging.bpkg'
    $InstrumentPackageList | ForEach-Object {
        InstallPackageViaBlaiseCli -ServerParkName $BlaiseServerPark -filePath $cmaInstrumentPath\$_ 
    }

    # Remove cma packages
    Remove-Item -LiteralPath $env:InstrumentPath\CMA.zip
    Remove-Item -LiteralPath $env:InstrumentPath\CMA\
}
catch{
    Write-Host "Installing cma packages failed: $($_.ScriptStackTrace)"
    exit 1
}



