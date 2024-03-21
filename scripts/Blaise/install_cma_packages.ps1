function InstrumentExists {
    param(
        [string] $ServerParkName,
        [string] $InstrumentName
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name argument provided"
    }

    If ([string]::IsNullOrEmpty($InstrumentName)) {
        throw [System.IO.ArgumentException] "No instrument name argument provided"
    }    

    $exists = c:\blaise5\bin\servermanager -listsurveys `
                                         -serverpark:$ServerParkName `
                                         -binding:http `
                                         -port:$env:ENV_BLAISE_CONNECTION_PORT `
                                         -user:$env:ENV_BLAISE_ADMIN_USER `
                                         -password:$env:ENV_BLAISE_ADMIN_PASSWORD `
                                        | findstr -i $InstrumentName                                        
                       
    If ([string]::IsNullOrEmpty($exists)) {
        return $false
    }

    return $true
}

function CheckFileExists {
    param(
        [string] $filePath
    )

    If ([string]::IsNullOrEmpty($filePath)) {
        throw [System.IO.ArgumentException] "No file path provided"
    }

    if (Test-Path $filePath)
        {
            return
        }

    Write-Host "File $filePath does not exist"
    exit 1        
}

function UnzipPackage {
    param(
        [string] $filePath,
        [string] $destinationPath
    )  

    If ([string]::IsNullOrEmpty($filePath)) {
        throw [System.IO.ArgumentException] "No file path provided"
    }

    If ([string]::IsNullOrEmpty($destinationPath)) {
        throw [System.IO.ArgumentException] "No destination path provided"
    }    

    CheckFileExists($filePath)

    try {
        "Exapnding zip file $filePath to $destinationPath"
        Expand-Archive -LiteralPath $filePath -DestinationPath $destinationPath -Force
    }
    catch {
        Write-Host "There was an error exapnding zip file $filePath to $destinationPath"
        exit 1  
    }
}

function InstallPackageViaServerManager{
    param(
        [string] $ServerParkName,
        [string] $filePath     
    )

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name provided"
    }

    If ([string]::IsNullOrEmpty($filePath)) {
        throw [System.IO.ArgumentException] "No file path provided"
    }

    CheckFileExists($filePath)

    try {
        "Iinstalling the package $filePath into the serverpark $ServerParkName via servermanager"
        c:\blaise5\bin\servermanager -installsurvey:$filePath `
                                     -serverpark:$ServerParkName `
                                     -binding:http `
                                     -port:$env:ENV_BLAISE_CONNECTION_PORT `
                                     -user:$env:ENV_BLAISE_ADMIN_USER `
                                     -password:$env:ENV_BLAISE_ADMIN_PASSWORD
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

    If ([string]::IsNullOrEmpty($ServerParkName)) {
        throw [System.IO.ArgumentException] "No server park name provided"
    }

    If ([string]::IsNullOrEmpty($filePath)) {
        throw [System.IO.ArgumentException] "No file path provided"
    }

    CheckFileExists($filePath)
    
    try {
        Write-Host "Installing the package $filePath into the serverpark $ServerParkName via the CLI"
        $InstrumentName = Split-Path -LeafBase $filePath
        C:\BlaiseServices\BlaiseCli\blaise.cli questionnaireinstall -s $ServerParkName -q $InstrumentName -f $filePath
       
    }
    catch {
        Write-Host "There was an error installing package $InstrumentName at $filePath into serverpark $ServerParkName"
        exit 1  
    }      
}

try{
    # Extract cma packages from multipackage file
    Write-Host "unzip cma multi package"
    UnzipPackage -filePath "$env:CmaInstrumentPath\$env:CmaMultiPackage" -destinationPath $env:CmaInstrumentPath

    # Install cma package via servermanager (as it does not contain a database)
    Write-Host "Install cma package via servermanager"
    InstallPackageViaServerManager -ServerParkName $env:CmaServerParkName -filePath $env:CmaInstrumentPath\CMA.bpkg

    # Install other packages via Bliase CLI to configure the datbaases to be cloud based
    Write-Host "Install other cma packages via cli"
    $InstrumentList = 'CMA_Attempts', 'CMA_ContactInfo', 'CMA_Launcher', 'CMA_Logging'
    $InstrumentList | ForEach-Object {     
        if(InstrumentExists -ServerParkName:$env:CmaServerParkName -InstrumentName:$_) {
            Write-Host "Instrument $_ already exists on $env:CmaServerParkName - don't install"
        }
        else {
            InstallPackageViaBlaiseCli -ServerParkName $env:CmaServerParkName `
            -filePath $env:CmaInstrumentPath\$_.bpkg 
        }           
    } 

    # Cleanup temporary cma packages folder
    Remove-Item -LiteralPath $env:CmaInstrumentPath -Force -Recurse
}
catch{
    Write-Host "Installing cma packages failed: $($_.ScriptStackTrace)"
    exit 1
}



