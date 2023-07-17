    # Service Name paramater
    param($ServiceName)

    if (Get-Service $ServiceName -ErrorAction SilentlyContinue)
    {

        $arrService = Get-Service -Name $ServiceName
        $serviceStatus = $arrService.Status

        if ($serviceStatus -eq "Running")
        {
	    Write-Information "Service $ServiceName is in the state $serviceStatus, will attempt to stop"

            Stop-Service $ServiceName
            Write-Information "Stopping $ServiceName service..."
            " ---------------------- "
            Start-Sleep 10

            $arrService_current = Get-Service -Name $ServiceName

            if ($arrService_current.Status -eq "Running")
            {
                Write-Information "Stopping $ServiceName service failed, kill the proces task"
                taskkill /f /pid (get-cimobject win32_service | Where-Object { $_.name -eq $ServiceName}).processID
            }

            Write-Information "Service $ServiceName has been stopped"
            sc.exe delete $ServiceName

            return
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "StartPending"))
        {
		       Write-Information "Service $arrService is in the state $serviceStatus, will attempt to stop process and delete service"

               Stop-Process -Name $ServiceName -Force
               sc.exe delete $ServiceName

               return
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "Stopped"))
        {
		    Write-Information "Service $arrService is in the state $serviceStatus, will attempt to delete service"

             sc.exe delete $ServiceName

             return
        }

        }
    else
    {
        Write-Information "Service doesn't exist"
    }
