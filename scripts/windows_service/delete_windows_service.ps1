param($ServiceName)

. "$PSScriptRoot\..\logging_functions.ps1"

if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {

    $arrService = Get-Service -Name $ServiceName
    $serviceStatus = $arrService.Status

    if ($serviceStatus -eq "Running") {
        LogInfo("Windows service $ServiceName is $serviceStatus")

        Stop-Service $ServiceName
        LogInfo("Stopping Windows service $ServiceName...")
        Start-Sleep 10

        $arrService_current = Get-Service -Name $ServiceName

        if ($arrService_current.Status -eq "Running") {
            LogInfo("Stopping Windows service $ServiceName failed, killing the process task...")
            taskkill /f /pid (get-cimobject win32_service | Where-Object { $_.name -eq $ServiceName }).processID
        }

        LogInfo("Windows service $ServiceName has been stopped, deleting...")
        sc.exe delete $ServiceName

        return
    }

    if ($serviceStatus -ne "running" -And ($serviceStatus -eq "StartPending")) {
        LogInfo("Windows service $arrService is $serviceStatus, deleting...")

        Stop-Process -Name $ServiceName -Force
        sc.exe delete $ServiceName

        return
    }

    if ($serviceStatus -ne "running" -And ($serviceStatus -eq "Stopped")) {
        LogInfo("Windows service $arrService is $serviceStatus, deleting...")

        sc.exe delete $ServiceName

        return
    }

}
else {
    LogInfo("Windows service $ServiceName doesn't exist")
}
