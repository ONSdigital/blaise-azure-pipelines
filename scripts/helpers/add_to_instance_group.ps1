param ($instancegroup, $zone)

try {
    $hostname = hostname
    gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
    Write-Information "added $hostname to the $instancegroup group"
}
catch {
    Write-Information "Unable to add $hostname to the instance group"
    exit 1
}
