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
        [string] $filePath
    )

    CheckFileExists($filePath)

    try {
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
        [string] $filePath
    )

    CheckFileExists($filePath)
}

function UnzipPackage {
    param(
        [string] $filePath
    )  

    CheckFileExists($filePath)

    try {
        Expand-Archive -Force $filePath
    }
    catch {
        Write-Host "There was an error exapnding zip file $filePath"
        exit 1  
    }
}

# Extract cma packages from multipackage file
Write-Host "unzip cma multi package"
UnzipPackage -filePath $env:InstrumentPath\cma\CMA.zip

# Install cma package via servermanager (as it does not contain a database)
Write-Host "Install cma package via servermanager"
InstallPackageViaServerManager -ServerParkName "cma" -filePath $env:InstrumentPath\cma\cma.bpkg
