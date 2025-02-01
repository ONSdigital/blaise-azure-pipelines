. "$PSScriptRoot\..\logging_functions.ps1"
. "$PSScriptRoot\..\update_script_environment_variables.ps1"

LogInfo("Installing Blaise $env:ENV_BLAISE_CURRENT_VERSION")

LogInfo("Downloading Blaise installer $env:ENV_BLAISE_INSTALL_PACKAGE from $BLAISE_GCP_BUCKET bucket...")
gsutil cp gs://$BLAISE_GCP_BUCKET/$env:ENV_BLAISE_INSTALL_PACKAGE "C:\dev\data"

$folderPath = "c:\dev\data\Blaise"
LogInfo("Unzipping $env:ENV_BLAISE_INSTALL_PACKAGE to $folderPath folder...")
Remove-Item $folderPath -Recurse -ErrorAction Ignore
mkdir $folderPath
Expand-Archive -Force C:\dev\data\$env:ENV_BLAISE_INSTALL_PACKAGE C:\dev\data\Blaise\

LogInfo("Setting Blaise install args...")
$blaiseInstallArgs = "/qn", "/norestart", "/log C:\dev\data\Blaise5-install.log", "/i C:\dev\data\Blaise\Blaise5.msi"
$blaiseInstallArgs += "FORCEINSTALL=1"
$blaiseInstallArgs += "USERNAME=`"ONS-USER`""
$blaiseInstallArgs += "COMPANYNAME=$BLAISE_LICENSEE"
$blaiseInstallArgs += "LICENSEE=$BLAISE_LICENSEE"
$blaiseInstallArgs += "SERIALNUMBER=$BLAISE_SERIALNUMBER"
$blaiseInstallArgs += "ACTIVATIONCODE=$BLAISE_ACTIVATIONCODE"
$blaiseInstallArgs += "INSTALLATIONTYPE=Server"
$blaiseInstallArgs += "IISWEBSERVERPORT=$BLAISE_IISWEBSERVERPORT"
$blaiseInstallArgs += "REGISTERASPNET=$BLAISE_REGISTERASPNET"
$blaiseInstallArgs += "MANAGEMENTCOMMUNICATIONPORT=$BLAISE_MANAGEMENTCOMMUNICATIONPORT"
$blaiseInstallArgs += "EXTERNALCOMMUNICATIONPORT=$BLAISE_EXTERNALCOMMUNICATIONPORT"
$blaiseInstallArgs += "SERVERPARK=$BLAISE_SERVERPARK"
$blaiseInstallArgs += "MACHINEKEY=$BLAISE_MACHINEKEY"
$blaiseInstallArgs += "ADMINISTRATORUSER=$BLAISE_ADMINUSER"
$blaiseInstallArgs += "ADMINISTRATORPASSWORD=$BLAISE_ADMINPASS"
$blaiseInstallArgs += "INSTALLDIR=$BLAISE_INSTALLDIR"
$blaiseInstallArgs += "DEPLOYFOLDER=$BLAISE_DEPLOYFOLDER"

# node roles
$blaiseInstallArgs += "MANAGEMENTSERVER=$BLAISE_MANAGEMENTSERVER"
$blaiseInstallArgs += "WEBSERVER=$BLAISE_WEBSERVER"
$blaiseInstallArgs += "DATAENTRYSERVER=$BLAISE_DATAENTRYSERVER"
$blaiseInstallArgs += "DATASERVER=$BLAISE_DATASERVER"
$blaiseInstallArgs += "RESOURCESERVER=$BLAISE_RESOURCESERVER"
$blaiseInstallArgs += "SESSIONSERVER=$BLAISE_SESSIONSERVER"
$blaiseInstallArgs += "AUDITTRAILSERVER=$BLAISE_AUDITTRAILSERVER"
$blaiseInstallArgs += "CATISERVER=$BLAISE_CATISERVER"

if ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.14") {
  LogInfo("Adding additional node roles for Blaise version 5.14 or greater")
  $blaiseInstallArgs += "DASHBOARDSERVER=$BLAISE_DASHBOARDSERVER"
  $blaiseInstallArgs += "CASEMANAGEMENTSERVER=$BLAISE_CASEMANAGEMENTSERVER"
  $blaiseInstallArgs += "PUBLISHSERVER=$BLAISE_PUBLISHSERVER"
  $blaiseInstallArgs += "EVENTSERVER=$BLAISE_EVENTSERVER"
  $blaiseInstallArgs += "CARISERVER=$BLAISE_CARISERVER"
}

LogInfo("blaiseInstallArgs: $blaiseInstallArgs")

LogInfo("Running Blaise installer via msiexec...")
Start-Process -Wait "msiexec" -ArgumentList $blaiseInstallArgs

LogInfo("Blaise $env:ENV_BLAISE_CURRENT_VERSION installed")
