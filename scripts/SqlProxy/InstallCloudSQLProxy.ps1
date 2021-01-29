Write-Host "Installing CloudSQL Proxy and NSSM Process"
Write-Host "GCP Bucket" $env:ENV_BLAISE_GCP_BUCKET
Write-Host "SQL Connect: " $env:ENV_CLOUDSQL_CONNECT

gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/nssm.exe" "C:\Windows\nssm.exe"
gsutil cp "gs://$env:ENV_BLAISE_GCP_BUCKET/cloud_sql_proxy_x64.exe" "C:\Windows\cloud_sql_proxy_x64.exe"
nssm.exe install cloudsql_proxy C:\Windows\cloud_sql_proxy_x64.exe -instances="$env:ENV_CLOUDSQL_CONNECT=tcp:3306" -ip_address_types=PRIVATE
nssm.exe set cloudsql_proxy Start SERVICE_AUTO_START
nssm.exe start cloudsql_proxy
