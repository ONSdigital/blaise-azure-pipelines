param ($instancegroup, $zone)

try {
    $hostname = hostname
    gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
    Write-Host "added $hostname to the $instancegroup group"
}
catch {
    Write-Host "Unable to add $hostname to the instance group"
    exit 1
}
