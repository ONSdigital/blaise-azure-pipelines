. "$PSScriptRoot\logging_functions.ps1"

param ($instancegroup, $zone)

    try {
        $hostname = hostname

        $instances = gcloud compute instance-groups unmanaged list-instances $instancegroup --zone $zone | Out-String

        if ($instances.Contains($hostname))
        {
            gcloud compute instance-groups unmanaged remove-instances $instancegroup --instances=$hostname --zone $zone
            LogInfo("Removed $hostname from $instancegroup instance group")
        }
    }
    catch {
        LogError("Unable to remove $hostname from $instancegroup instance group")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        exit 1
    }
