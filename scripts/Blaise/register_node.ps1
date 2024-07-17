$CurrentNode = $(hostname)
$BlaiseManagementNode = $env:ENV_BLAISE_SERVER_HOST_NAME
$BlaiseConnectionPort = $env:ENV_BLAISE_CONNECTION_PORT
$BlaiseAdminUser = $env:ENV_BLAISE_ADMIN_USER
$BlaiseAdminPassword = $env:ENV_BLAISE_ADMIN_PASSWORD
$BlaiseServerParkName = $env:ENV_BLAISE_SERVER_PARK_NAME
$BlaiseCmaServerParkName = $env:CmaServerParkName

if ([string]::IsNullOrEmpty($CurrentNode) -or
    [string]::IsNullOrEmpty($BlaiseManagementNode) -or
    [string]::IsNullOrEmpty($BlaiseConnectionPort) -or
    [string]::IsNullOrEmpty($BlaiseAdminUser) -or
    [string]::IsNullOrEmpty($BlaiseAdminPassword) -or
    [string]::IsNullOrEmpty($BlaiseServerParkName) -or
    [string]::IsNullOrEmpty($BlaiseCmaServerParkName)) {
    Write-Host "Required environment variables are not set"
    exit 1
}

function Register-Node {
    param(
        [string] $ServerPark
    )
    $RetryCount = 0
    do {
        Write-Host "Registering node '$CurrentNode' on management node '$BlaiseManagementNode' for server park '$ServerPark'"
        c:\blaise5\bin\servermanager.exe -addserverparkserver:$CurrentNode `
            -server:$BlaiseManagementNode `
            -user:$BlaiseAdminUser `
            -password:$BlaiseAdminPassword `
            -serverpark:$ServerPark `
            -serverport:$BlaiseConnectionPort `
            -serverbinding:http `
            -masterhostname:$BlaiseManagementNode `
            -logicalroot:default `
            -binding:http `
            -port:$BlaiseConnectionPort
        Write-Host "Attempt to register node '$CurrentNode' on management node '$BlaiseManagementNode' for server park '$ServerPark' completed"

        $DidNodeRegister = Check-NodeRegistered -ServerPark $ServerPark
        if ($DidNodeRegister) {
            Write-Host "Node '$CurrentNode' is registered on management node '$BlaiseManagementNode' for server park '$ServerPark'"
            break
        } else {
            Write-Host "Node '$CurrentNode' is not registered on management node '$BlaiseManagementNode' for server park '$ServerPark', retrying in 5 seconds..."
            Start-Sleep -Seconds 5
            $RetryCount++
        }
    } while ($RetryCount -lt 3)
    if (-not $DidNodeRegister) {
        Write-Host "Failed to register node '$CurrentNode' on management node '$BlaiseManagementNode' for server park '$ServerPark' after 3 retries"
        exit 1
    }
}

function Check-NodeRegistered {
    param(
        [string] $ServerPark
    )
    $IsNodeRegistered = c:\blaise5\bin\servermanager.exe -listserverparkservers `
        -server:$BlaiseManagementNode `
        -user:$BlaiseAdminUser `
        -password:$BlaiseAdminPassword `
        -serverpark:$ServerPark | findstr -i $(hostname)
    return -not [string]::IsNullOrEmpty($IsNodeRegistered)
}

try {
    Register-Node -ServerPark:$BlaiseServerParkName
    Register-Node -ServerPark:$BlaiseCmaServerParkName
} catch {
    Write-Host "Error registering node"
    Write-Host "Error message: $($_.Exception.Message)"
    Write-Host "Script stack trace: $($_.ScriptStackTrace)"
    exit 1
}
