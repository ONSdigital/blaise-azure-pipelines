##################
# Declare ariables
##################

$MysqlConnectorPackage = 'mysql-connector-net-8.0.22.msi'
$GcpBucket = $env:ENV_SHARED_BUCKET
$InstallPath = 'C:\dev\mysql'

##########################
# INSTALL MYSQL Connectors
##########################

# Download package
Write-Host "Download Mysql connector from '$GcpBucket'"
gsutil cp gs://$GcpBucket/$MysqlConnectorPackage $InstallPath

# Install package
Write-Host "Installing MYSQL connector: 8.0.22"
msiexec /i $InstallPath\$MysqlConnectorPackage
Write-Host "Installed mysql connectors"