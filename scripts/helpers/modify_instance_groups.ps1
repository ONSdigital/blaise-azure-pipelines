function addtoloadbalancer {
    param (
        [string] $instancegroup, 
        [string] $zone
    )
    try {
        gcloud compute instance-groups unmanaged add-instances $instancegroup --instances=$hostname --zone $zone
        Write-Host "added $hostname to the $instancegroup group"
    }
    catch {
        Write-Host "Unable to add $hostname to the instance group"
        exit 1
    }
}

function removefromloadbalancer {
    param (
        [string] $instancegroup, 
        [string] $zone
    )
    try {
        gcloud compute instance-groups unmanaged remove-instances $instancegroup --instances=$hostname --zone $zone
        Write-Host "removed $hostname from $instancegroup group"
    }
    catch {
        Write-Host "Unable to remove $hostname from the instance group"
        exit 1
    }
}
