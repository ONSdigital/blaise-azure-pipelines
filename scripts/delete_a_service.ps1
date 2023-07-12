    # Service Name paramater
    param($ServiceName)

    if (Get-Service $ServiceName -ErrorAction SilentlyContinue)
    {

        $arrService = Get-Service -Name $ServiceName
        $serviceStatus = $arrService.Status

        if ($serviceStatus -eq "Running")
        {
	    Write-Output "Service $ServiceName is in the state $serviceStatus, will attempt to stop"

            Stop-Service $ServiceName
            Write-Output "Stopping " $ServiceName " service..."
            " ---------------------- "
            Start-Sleep 10

            $arrService_current = Get-Service -Name $ServiceName

            if ($arrService_current.Status -eq "Running")
            {
                Write-Output "Stopping " $ServiceName " service failed, kill the proces task"
                taskkill /f /pid (get-cimobject win32_service | Where-Object { $_.name -eq $ServiceName}).processID
            }

            Write-Output "Service $ServiceName has been stopped"
            sc.exe delete $ServiceName

            return
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "StartPending"))
        {
		       Write-Output "Service $arrService is in the state $serviceStatus, will attempt to stop process and delete service"

               Stop-Process -Name $ServiceName -Force
               sc.exe delete $ServiceName

               return
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "Stopped"))
        {
		    Write-Output "Service $arrService is in the state $serviceStatus, will attempt to delete service"

             sc.exe delete $ServiceName

             return
        }

        }
    else
    {
        Write-Output "Service doesn't exist"
    }
