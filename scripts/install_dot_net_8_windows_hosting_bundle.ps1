param ([string]$GCP_BUCKET)

. "$PSScriptRoot\logging_functions.ps1"

if (Test-Path C:\dev\data\dotnet-hosting-8.0.14-win.exe) {
    LogInfo(".NET8 Windows Hosting Bundle already installed, skipping...")
}
else {
    LogInfo("Downloading and installing .NET8 Windows Hosting Bundle...")
    gsutil cp gs://$GCP_BUCKET/dotnet-hosting-8.0.14-win.exe "C:\dev\data\dotnet-hosting-8.0.14-win.exe"
    Start-Process -FilePath "C:\dev\data\dotnet-hosting-8.0.14-win.exe" -ArgumentList "/quiet /norestart" -NoNewWindow -Wait

}