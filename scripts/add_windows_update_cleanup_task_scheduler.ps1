function GetSecretValue {
    param ([string]$variable)
    
    Write-Host "Running GetSecretValue..."

    # If varValue is a secret
    if ($variable -Like "projects/*/secrets/*") {
        $parts = $variable -split "/"
        $secret = $parts[3]

        $secretValue = & gcloud secrets versions access latest --secret=$secret

        return $secretValue
    }

    return $variable
}



function Set-UpdateCleanupStateFlags {
    Write-Host 'Enabling Update Cleanup.'
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0099 -Value 2 -Type DWord
}
    
$taskName = "WindowsUpdateCleanup"  # Set the task name
$executionTime = "22:00"            # Set the desired execution time (24-hour format)
$executionDay = "1"                 # Set the desired execution day (1-31)
    
# Check if a task with the same name already exists
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Task '$taskName' already exists. Skipping creation."
} 
else {
    # Call function to set Windows Update Flags for Cleanup
    Set-UpdateCleanupStateFlags

    # Added for debugging purposes
    Write-Host "Current User: $(whoami)"
    Write-Host "Execution Policy: $(Get-ExecutionPolicy)"

    $BLAISE_ADMINUSER = Invoke-RestMethod "http://metadata.google.internal/computeMetadata/v1/instance/attributes/BLAISE_ADMINUSER" -Headers @{"Metadata-Flavor" = "Google" }
    $BLAISE_ADMINPASS = Invoke-RestMethod "http://metadata.google.internal/computeMetadata/v1/instance/attributes/BLAISE_ADMINPASS" -Headers @{"Metadata-Flavor" = "Google" }
    $BLAISE_ADMINPASS = GetSecretValue($BLAISE_ADMINPASS)

    Write-Host "$BLAISE_ADMINUSER"
    Write-Host "$BLAISE_ADMINPASS"

    schtasks.exe /Create /SC MONTHLY /D $executionDay /TN $taskName /TR "cleanmgr.exe /sagerun:99" /ST $executionTime /RL HIGHEST /RU $BLAISE_ADMINUSER /RP $BLAISE_ADMINPASS
    Write-Host "Task '$taskName' created successfully."
}