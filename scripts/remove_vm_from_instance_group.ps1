param ($instancegroup, $zone)

    try {
        $hostname = hostname

        $instances = gcloud compute instance-groups unmanaged list-instances $instancegroup --zone $zone | Out-String

        if ($instances.Contains($hostname))
        {
            gcloud compute instance-groups unmanaged remove-instances $instancegroup --instances=$hostname --zone $zone
            Write-Host "Removed $hostname from $instancegroup instance group"
        }
    }
    catch {
        Write-Host "Unable to remove $hostname from $instancegroup instance group"
        exit 1
    }
