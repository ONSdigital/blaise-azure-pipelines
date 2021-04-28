function NodeHasTheCorrectRoles {
    $requiredRoles = RolesNodeShouldHave
    $currentRoles = ParseCurrentNodeRoles
    return CheckNodeHasCorrectRoles -CurrentNodeRoles $currentRoles -RolesNodeShouldHave $requiredRoles
}
function RolesNodeShouldHave {
    Write-Host "Setting up script and system variables..."
    $metadataVariables = GetMetadataVariables
    CreateVariables($metadataVariables)
    [System.Environment]::SetEnvironmentVariable('ENV_BLAISE_ROLES',$BLAISE_ROLES,[System.EnvironmentVariableTarget]::Machine)

    $rolesItShouldHave = $env:ENV_BLAISE_ROLES.Trim().Split(',') | Sort-Object
    return $rolesItShouldHave -join ','
}

function CurrentNodeRoles {
    return C:\Blaise5\Bin\ServerManager -lsr | Out-String
}

function ParseCurrentNodeRoles {
    param (
        [string] $CurrentRoles
    )
    if ([string]::IsNullOrEmpty($CurrentRoles))
    {
        $CurrentRoles = CurrentNodeRoles
    }
    $roles = ""

    Switch -regex ($CurrentRoles)
    {
        'ADMIN' { $roles += 'admin,' }
        'CATI' { $roles += 'cati,' }
        'AUDITTRAIL' { $roles += 'audittrail,' }
        'WEB' { $roles += 'web,' }
        'SESSION' { $roles += 'session,' }
        'DATA' { $roles += 'data,' }
        'RESOURCE' { $roles += 'resource,' }
        'DATAENTRY' { $roles += 'dataentry,' }
        'DASHBOARD' { $roles += 'dashboard' }
    }

    $roles = $roles.Trim().Split(',') | Sort-Object
    return $roles -join ','
}

function CheckNodeHasCorrectRoles {
    param (
        [string] $CurrentNodeRoles,
        [string] $RolesNodeShouldHave
    )
    return $CurrentNodeRoles -eq $RolesNodeShouldHave
}

function GetMetadataVariables
{
  $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
  return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables($variableList)
{
  # start
  # get the blaise install vars
  $blaise_install_vars = $variableList.Clone()
  Write-Host "Got vars: $blaise_install_vars"
  $blaise_install_var_keys = @($variableList.Keys)
  Write-Host "Got Keys: $blaise_install_var_keys"

  $blaise_install_var_keys | ForEach-Object {
    if ($_ -notmatch "BLAISE_.*") {
      $blaise_install_vars.Remove($_)
    }
  }

  # drop the BLAISE_ prefix and concat kv pairs into a string array
  $global:blaise_install_params = $blaise_install_vars.GetEnumerator().ForEach({ "$($_.Name.substring(7))=$($_.Value)" })
  #### end


  # original foreach processing...
  foreach ($variable in $variableList)
  {
    $varName = $variable.Name
    $varValue = $variable.Definition

    # The variable value (varValue) above is in the format NAME = VALUE.
    # We only want the variables that include 'BLAISE' or 'SCRIPT' in the name
    # This pattern will help extract the VALUE by removing the 'NAME =' part.
    $pattern = "^(.*?)$([regex]::Escape($varName) )(.?=)(.*)"

    if ($varName -Like "BLAISE_*" -or $varName -Like "SCRIPT_*")
    {
      New-Variable -Scope script -Name ($varName -replace "BLAISE_", "") -Value ($varValue -replace $pattern, '$3')
      Write-Host "Script Var: $varName = $( $varValue -replace $pattern, '$3' )"
    }
    if ($varName -Like "ENV_*")
    {
      [System.Environment]::SetEnvironmentVariable($varName, ($varValue -replace $pattern, '$3'), [System.EnvironmentVariableTarget]::Machine)
      Write-Host "Env Var   : $varName = $( $varValue -replace $pattern, '$3' )"
    }
  }
}
