param ($instancegroup, $zone)

    try {
        $hostname = hostname

        $instances = gcloud compute instance-groups unmanaged list-instances $instancegroup --zone $zone | Out-String

        if ($instances.Contains($hostname))
        {
            gcloud compute instance-groups unmanaged remove-instances $instancegroup --instances=$hostname --zone $zone
            Write-Host "removed $hostname from $instancegroup group"
        }
    }
    catch {
        Write-Host "Unable to remove $hostname from the instance group"
        exit 1
    }
