function CreateDataInterfaceFile {
    param (
        [string] $applicationType, 
        [string] $filePath
    )
    C:\BlaiseServices\BlaiseCli\blaise.cli datainterface -t $applicationType -f $filePath

}

function RegisterCatiDataInterfaceFile {
    param (
        [string] $filePath
    )
    c:\blaise5\bin\servermanager -ecs -catidatainterface:$filePath
}

