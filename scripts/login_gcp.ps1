. "$PSScriptRoot\logging_functions.ps1"

LogInfo("Logging into GCP with VM service account")
gcloud auth login $env:ENV_VM_SERVICEACCOUNT
