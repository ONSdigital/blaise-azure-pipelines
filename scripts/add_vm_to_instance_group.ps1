param ($instancegroup, $zone)

try {
    $hostname = hostname
    gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
    Write-Host "Added $hostname to $instancegroup instance group"
}
catch {
    Write-Host "Unable to add $hostname to $instancegroup instance group"
    exit 1
}
