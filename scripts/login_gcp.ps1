. "$PSScriptRoot\logging_functions.ps1"

$env:PATH += ";C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin"
LogInfo("Logging into GCP with VM service account")
gcloud auth login $env:ENV_VM_SERVICEACCOUNT