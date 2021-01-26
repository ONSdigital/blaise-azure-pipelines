    # Service Name paramater
    param($ServiceName)
    
    if (Get-Service $ServiceName -ErrorAction SilentlyContinue)
    {

        $arrService = Get-Service -Name $ServiceName
        $serviceStatus = $arrService.Status

        if ($serviceStatus -eq "Running")
        {
	    Write-Host "Service $ServiceName is in the state $serviceStatus, will attempt to stop"
		 
            Stop-Service $ServiceName
            Write-Host "Stopping " $ServiceName " service..."
            " ---------------------- "
            sleep 10

            $arrService_current = Get-Service -Name $ServiceName

            if ($arrService_current.Status -eq "Running")
            {
                Write-Host "Stopping " $ServiceName " service failed, kill the proces task"
                taskkill /f /pid (get-wmiobject win32_service | where { $_.name -eq $ServiceName}).processID
            }		
			
            Write-Host "Service $(Build.DefinitionName) has been stopped"
            sc.exe delete $ServiceName

            return 
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "StartPending"))
        {
		       Write-Host "Service $arrService is in the state $serviceStatus, will attempt to stop process and delete service"
			
               Stop-Process -Name $ServiceName -Force
               sc.exe delete $ServiceName

               return 
        }

        if ($serviceStatus -ne "running" -And ($serviceStatus -eq "Stopped"))
        {
		    Write-Host "Service $arrService is in the state $serviceStatus, will attempt to delete service"
		
             sc.exe delete $ServiceName

             return 
        }

        }
    else 
    {
        Write-Host "Service doesn't exist"
    }
