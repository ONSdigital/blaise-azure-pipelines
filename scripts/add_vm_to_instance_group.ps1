param ($instancegroup, $zone)

. "$PSScriptRoot\logging_functions.ps1"

try {
    $hostname = hostname
    gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
    LogInfo("Added $hostname to $instancegroup instance group")
}
catch {
    LogError("Unable to add $hostname to $instancegroup instance group")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}
