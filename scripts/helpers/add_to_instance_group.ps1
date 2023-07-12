param ($instancegroup, $zone)

try {
    $hostname = hostname
    gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
    Write-Output "added $hostname to the $instancegroup group"
}
catch {
    Write-Output "Unable to add $hostname to the instance group"
    exit 1
}
