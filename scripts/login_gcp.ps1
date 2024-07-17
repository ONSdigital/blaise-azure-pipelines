Write-Host "Logging into GCP with VM service account"
gcloud auth login $env:ENV_VM_SERVICEACCOUNT
