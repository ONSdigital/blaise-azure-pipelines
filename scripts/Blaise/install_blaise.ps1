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
      Write-Information "Script Env Var - $varName = $varValue"
    }
  }
}

###############
# RUNTIME ARGS
###############

Write-Information "Setting up script environment variables..."
$metadataVariables = GetMetadataVariables1
CreateVariables1($metadataVariables)
[System.Environment]::SetEnvironmentVariable('ENV_BLAISE_SERVER_ROLES',$BLAISE_ROLES,[System.EnvironmentVariableTarget]::Machine)

#################
# INSTALL BLAISE
#################

Write-Information "Installing Blaise version: $env:ENV_BLAISE_CURRENT_VERSION"

Write-Information "LICENSEE: $BLAISE_LICENSEE"
Write-Information "INSTALLDIR: $BLAISE_INSTALLDIR"
Write-Information "DEPLOYFOLDER: $BLAISE_DEPLOYFOLDER"
Write-Information "SERVERPARK: $BLAISE_SERVERPARK"
Write-Information "GCP_BUCKET: $BLAISE_GCP_BUCKET"

Write-Information "Download Blaise redistributables from '$BLAISE_GCP_BUCKET'"
gsutil cp gs://$BLAISE_GCP_BUCKET/$env:ENV_BLAISE_INSTALL_PACKAGE "C:\dev\data"

# unzip blaise installer
$folderPath = "c:\dev\data\Blaise"
Write-Information "Expanding archive to 'Blaise' dir"
Remove-Item $folderPath -Recurse -ErrorAction Ignore
mkdir $folderPath
Expand-Archive -Force C:\dev\data\$env:ENV_BLAISE_INSTALL_PACKAGE C:\dev\data\Blaise\

Write-Information "Setting Blaise install args"
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

# server park roles
$blaise_args += "MANAGEMENTSERVER=$BLAISE_MANAGEMENTSERVER"
$blaise_args += "WEBSERVER=$BLAISE_WEBSERVER"
$blaise_args += "DATAENTRYSERVER=$BLAISE_DATAENTRYSERVER"
$blaise_args += "DATASERVER=$BLAISE_DATASERVER"
$blaise_args += "RESOURCESERVER=$BLAISE_RESOURCESERVER"
$blaise_args += "SESSIONSERVER=$BLAISE_SESSIONSERVER"
$blaise_args += "AUDITTRAILSERVER=$BLAISE_AUDITTRAILSERVER"
$blaise_args += "CATISERVER=$BLAISE_CATISERVER"

Write-Information "blaise_args: $blaise_args"

Write-Information "Running msiexec"
Start-Process -Wait "msiexec" -ArgumentList $blaise_args

Write-Information "Blaise installation complete"