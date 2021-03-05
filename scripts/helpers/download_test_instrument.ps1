Write-Host "Login to GCP"
gcloud auth activate-service-account $env:ENV_SHARED_SERVICE_ACCOUNT --key-file=$(gcpkey.secureFilePath)

Write-Host "Downloading instrument"
gsutil cp gs://$env:ENV_SHARED_BUCKET/$env:InstrumentName.bpkg c:\survey\$env:InstrumentName.bpkg