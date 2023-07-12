Write-Output "Login to GCP"
gcloud auth activate-service-account $env:ENV_SHARED_SERVICE_ACCOUNT --key-file=$(gcpkey.secureFilePath)

Write-Output "Downloading instrument"
gsutil cp gs://$env:ENV_SHARED_BUCKET/$env:InstrumentName.$env:PACKAGE_EXTENSION $env:InstrumentPath\$env:InstrumentName.bpkg

Write-Output "GCP Login with compute service account"
gcloud config set account $env:ENV_VM_SERVICEACCOUNT
