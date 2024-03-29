$CmaInstrumentPath = $env:CmaInstrumentPath
$CmaMultiPackage = $env:CmaMultiPackage
$CmaServerParkName = $env:CmaServerParkName

$BlaiseConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT
$BlaiseAdminUser = $env:ENV_BLAISE_ADMIN_USER
$BlaiseAdminPassword = $env:ENV_BLAISE_ADMIN_PASSWORD

function Test-InstrumentInstalled {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerParkName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InstrumentName
    )

    $IsInstrumentInstalled = & "C:\blaise5\bin\servermanager.exe" -listsurveys `
        -serverpark:$ServerParkName `
        -binding:http `
        -port:$BlaiseConnectionPort `
        -user:$BlaiseAdminUser `
        -password:$BlaiseAdminPassword | Select-String -Pattern $InstrumentName -SimpleMatch

    return ($null -ne $IsInstrumentInstalled)
}

function Test-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    return (Test-Path -Path $FilePath -PathType Leaf)
}

function Expand-ZipFile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath
    )

    if (-not (Test-FileExists -FilePath $FilePath)) {
        throw "File '$FilePath' does not exist."
    }

    Write-Host "Expanding zip file '$FilePath' to '$DestinationPath'"
    Expand-Archive -LiteralPath $FilePath -DestinationPath $DestinationPath -Force
}

function Install-PackageViaServerManager {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerParkName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    if (-not (Test-FileExists -FilePath $FilePath)) {
        throw "File '$FilePath' does not exist."
    }

    Write-Host "Installing package '$FilePath' into server park '$ServerParkName' via Server Manager"
    & "C:\blaise5\bin\servermanager.exe" -installsurvey:$FilePath `
        -serverpark:$ServerParkName `
        -binding:http `
        -port:$BlaiseConnectionPort `
        -user:$BlaiseAdminUser `
        -password:$BlaiseAdminPassword
}

function Install-PackageViaBlaiseCli {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerParkName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    if (-not (Test-FileExists -FilePath $FilePath)) {
        throw "File '$FilePath' does not exist."
    }

    $InstrumentName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    Write-Host "Installing package '$InstrumentName' from '$FilePath' into server park '$ServerParkName' via Blaise CLI"
    & "C:\BlaiseServices\BlaiseCli\blaise.cli.exe" questionnaireinstall -s $ServerParkName -q $InstrumentName -f $FilePath
}

try {
    Write-Host "Unzipping CMA multi-package '$CmaMultiPackage'"
    Expand-ZipFile -FilePath "$CmaInstrumentPath\$CmaMultiPackage" -DestinationPath $CmaInstrumentPath

    # Install the "CMA" package via Server Manager as it does not use a data interface / database
    Install-PackageViaServerManager -ServerParkName $CmaServerParkName -FilePath "$CmaInstrumentPath\CMA.bpkg"

    # Install remaining CMA instruments using Blaise CLI for MySQL data interface database configuration
    $InstrumentList = 'CMA_Attempts', 'CMA_ContactInfo', 'CMA_Launcher', 'CMA_Logging'
    foreach ($Instrument in $InstrumentList) {
        if (Test-InstrumentInstalled -ServerParkName $CmaServerParkName -InstrumentName $Instrument) {
            Write-Host "Instrument '$Instrument' already installed on server park '$CmaServerParkName' - skipping installation"
        }
        else {
            Install-PackageViaBlaiseCli -ServerParkName $CmaServerParkName -FilePath "$CmaInstrumentPath\$Instrument.bpkg"
        }
    }

    Write-Host "Removing CMA working folder '$CmaInstrumentPath'"
    Remove-Item -LiteralPath $CmaInstrumentPath -Force -Recurse
}
catch {
    Write-Error "Installing CMA packages failed: $($_.Exception.Message)"
    Write-Error "$($_.ScriptStackTrace)"
    exit 1
}
 