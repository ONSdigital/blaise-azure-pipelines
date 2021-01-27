Write-Host "Installing CloudSQL Proxy and NSSM Process"
gsutil cp "gs://$env:BLAISE_GCP_BUCKET/nssm.exe" "C:\Windows\nssm.exe"
gsutil cp "gs://$env:BLAISE_GCP_BUCKET/cloud_sql_proxy_x64.exe" "C:\Windows\cloud_sql_proxy_x64.exe"
nssm install cloudsql_proxy C:\Windows\cloud_sql_proxy_x64.exe -instances="$env:ENV_CLOUDSQL_CONNECT=tcp:3306" -ip_address_types=PRIVATE
nssm set cloudsql_proxy Start SERVICE_AUTO_START
nssm start cloudsql_proxy
