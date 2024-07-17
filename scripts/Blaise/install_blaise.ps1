. "$PSScriptRoot\..\logging_functions.ps1"

############
# functions
############

function GetMetadataVariables1
{
  $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
  return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables1($variableList)
{
  foreach ($variable in $variableList)
  {
    if ($variable.Name -Like "BLAISE_*")
    {
      $varName = $variable.Name
      $varDefinition = $variable.Definition
      $pattern = "^(.*?)$([regex]::Escape($varName))(.?=)(.*)"
      $varValue = ($varDefinition -replace $pattern, '$3')
      New-Variable -Scope script -Name ($varName) -Value $varValue -Force
      LogInfo("Script env var - $varName = $varValue")
    }
  }
}

###############
# RUNTIME ARGS
###############

LogInfo("Setting up script environment variables...")
$metadataVariables = GetMetadataVariables1
CreateVariables1($metadataVariables)
[System.Environment]::SetEnvironmentVariable('ENV_BLAISE_SERVER_ROLES',$BLAISE_ROLES,[System.EnvironmentVariableTarget]::Machine)

#################
# INSTALL BLAISE
#################

LogInfo("Installing Blaise $env:ENV_BLAISE_CURRENT_VERSION")

LogInfo("Downloading Blaise installer $env:ENV_BLAISE_INSTALL_PACKAGE from $BLAISE_GCP_BUCKET bucket...")
gsutil cp gs://$BLAISE_GCP_BUCKET/$env:ENV_BLAISE_INSTALL_PACKAGE "C:\dev\data"

$folderPath = "c:\dev\data\Blaise"
LogInfo("Unzipping Blaise installer to 'C:\dev\data\Blaise\' folder...")
Remove-Item $folderPath -Recurse -ErrorAction Ignore
mkdir $folderPath
Expand-Archive -Force C:\dev\data\$env:ENV_BLAISE_INSTALL_PACKAGE C:\dev\data\Blaise\

LogInfo("Setting Blaise install args...")
$blaise_args = "/qn","/norestart","/log C:\dev\data\Blaise5-install.log","/i C:\dev\data\Blaise\Blaise5.msi"
$blaise_args += "FORCEINSTALL=1"
$blaise_args += "USERNAME=`"ONS-USER`""
$blaise_args += "COMPANYNAME=$BLAISE_LICENSEE"
$blaise_args += "LICENSEE=$BLAISE_LICENSEE"
$blaise_args += "SERIALNUMBER=$BLAISE_SERIALNUMBER"
$blaise_args += "ACTIVATIONCODE=$BLAISE_ACTIVATIONCODE"
$blaise_args += "INSTALLATIONTYPE=Server"
$blaise_args += "IISWEBSERVERPORT=$BLAISE_IISWEBSERVERPORT"
$blaise_args += "REGISTERASPNET=$BLAISE_REGISTERASPNET"
$blaise_args += "MANAGEMENTCOMMUNICATIONPORT=$BLAISE_MANAGEMENTCOMMUNICATIONPORT"
$blaise_args += "EXTERNALCOMMUNICATIONPORT=$BLAISE_EXTERNALCOMMUNICATIONPORT"
$blaise_args += "SERVERPARK=$BLAISE_SERVERPARK"
$blaise_args += "MACHINEKEY=$BLAISE_MACHINEKEY"
$blaise_args += "ADMINISTRATORUSER=$BLAISE_ADMINUSER"
$blaise_args += "ADMINISTRATORPASSWORD=$BLAISE_ADMINPASS"
$blaise_args += "INSTALLDIR=$BLAISE_INSTALLDIR"
$blaise_args += "DEPLOYFOLDER=$BLAISE_DEPLOYFOLDER"

# node roles
$blaise_args += "MANAGEMENTSERVER=$BLAISE_MANAGEMENTSERVER"
$blaise_args += "WEBSERVER=$BLAISE_WEBSERVER"
$blaise_args += "DATAENTRYSERVER=$BLAISE_DATAENTRYSERVER"
$blaise_args += "DATASERVER=$BLAISE_DATASERVER"
$blaise_args += "RESOURCESERVER=$BLAISE_RESOURCESERVER"
$blaise_args += "SESSIONSERVER=$BLAISE_SESSIONSERVER"
$blaise_args += "AUDITTRAILSERVER=$BLAISE_AUDITTRAILSERVER"
$blaise_args += "CATISERVER=$BLAISE_CATISERVER"

if ($env:ENV_BLAISE_CURRENT_VERSION -ge "5.14") {
    LogInfo("Adding additional node roles for Blaise version 5.14 or greater")
    $blaise_args += "DASHBOARDSERVER=$BLAISE_DASHBOARDSERVER"
    $blaise_args += "CASEMANAGEMENTSERVER=$BLAISE_CASEMANAGEMENTSERVER"
    $blaise_args += "PUBLISHSERVER=$BLAISE_PUBLISHSERVER"
    $blaise_args += "EVENTSERVER=$BLAISE_EVENTSERVER"
    $blaise_args += "CARISERVER=$BLAISE_CARISERVER"
}

LogInfo("blaise_args: $blaise_args")

LogInfo("Running Blaise installer via msiexec...")
Start-Process -Wait "msiexec" -ArgumentList $blaise_args

LogInfo("Blaise $env:ENV_BLAISE_CURRENT_VERSION installed")