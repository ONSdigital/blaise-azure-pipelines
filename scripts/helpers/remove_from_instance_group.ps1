param ($instancegroup, $zone)

    try {
        $hostname = hostname
        gcloud compute instance-groups unmanaged remove-instances $instancegroup --instances=$hostname --zone $zone
        Write-Host "removed $hostname from $instancegroup group"
    }
    catch {
        Write-Host "Unable to remove $hostname from the instance group"
        exit 1
    }

