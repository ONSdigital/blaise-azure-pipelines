Write-Host "Login to GCP"
gcloud auth activate-service-account $env:ENV_SHARED_SERVICE_ACCOUNT --key-file=$(gcpkey.secureFilePath)

Write-Host "Downloading instrument"
gsutil cp gs://$env:ENV_SHARED_BUCKET/$env:InstrumentName.$env:PACKAGE_EXTENSION $env:InstrumentPath\$env:InstrumentName.bpkg

Write-Host "GCP Login with compute service account"
gcloud auth login $env:ENV_VM_SERVICEACCOUNT
