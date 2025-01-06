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
    Write-Host 'Setting Update Cleanup Flag...'
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0099 -Value 2 -Type DWord
    Write-Host 'Setting Update Cleanup Flag...'
}
    
$taskName = "WindowsUpdateCleanup"  # Set the task name
$executionTime = "12:15"            # Set the desired execution time (24-hour format)
$executionDay = "6"                 # Set the desired execution day (1-31)
    
# Check if a task with the same name already exists
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Task '$taskName' already exists. Deleteing old task..."
    schtasks.exe /DELETE /TN $taskName /F
    Write-Host "Task '$taskName' successfully deleted."
} 

# Call function to set Windows Update Flags for Cleanup
Set-UpdateCleanupStateFlags

# Added for debugging purposes
Write-Host "Current User: $(whoami)"
Write-Host "Execution Policy: $(Get-ExecutionPolicy)"

$BLAISE_WINDOWS_USERNAME = Invoke-RestMethod "http://metadata.google.internal/computeMetadata/v1/instance/attributes/BLAISE_WINDOWS_USERNAME" -Headers @{"Metadata-Flavor" = "Google" }
$BLAISE_WINDOWS_PASSWORD = Invoke-RestMethod "http://metadata.google.internal/computeMetadata/v1/instance/attributes/BLAISE_WINDOWS_PASSWORD" -Headers @{"Metadata-Flavor" = "Google" }
$BLAISE_WINDOWS_PASSWORD = GetSecretValue($BLAISE_WINDOWS_PASSWORD)

Write-Host "$BLAISE_WINDOWS_USERNAME"
Write-Host "$BLAISE_WINDOWS_PASSWORD"

Write-Host "Creating '$taskName' Scheduled task..."
schtasks.exe /Create /SC MONTHLY /D $executionDay /TN $taskName /TR "cleanmgr.exe /sagerun:99" /ST $executionTime /RL HIGHEST /RU $BLAISE_WINDOWS_USERNAME /RP $BLAISE_WINDOWS_PASSWORD
Write-Host "Task '$taskName' created successfully."
