#############
# functions
############
function GetMetadataVariables1
{
  $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
  return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables1($variableList)
{
  # start
  # get the blaise install vars
 # $blaise_install_vars = $variableList.Clone()
  #Write-Host "Got vars: $blaise_install_vars"
  #$blaise_install_var_keys = @($variableList.Keys)
  #Write-Host "Got Keys: $blaise_install_var_keys"

  # drop the BLAISE_ prefix and concat kv pairs into a string array
  #$global:blaise_install_params = $variableList.GetEnumerator().ForEach({ "$($_.Name.substring(7))=$($_.Value)" })
  #### end


  # original foreach processing...
  foreach ($variable in $variableList)
  {
      if ($variable.Name -Like "BLAISE_*")
      {
        $varName = $variable.Name
        $varValue = $variable.Definition

        $pattern = "^(.*?)$([regex]::Escape($varName) )(.?=)(.*)"

         New-Variable -Scope script -Name ($varName) -Value ($varValue -replace $pattern, '$3')

         Write-Host $varName '=' ($varValue -replace $pattern, '$3')
        }
  }
}

###############
# RUNTIME ARGS
###############

Write-Host "Setting up script and system variables..."
$metadataVariables = GetMetadataVariables1
CreateVariables1($metadataVariables)
