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

  foreach ($variable in $variableList)
  {
      if ($variable.Name -Like "BLAISE_*")
      {
        $varName = $variable.Name
        $varValue = $variable.Definition

        $pattern = "^(.*?)$([regex]::Escape($varName) )(.?=)(.*)"

         New-Variable -Scope script -Name ($varName) -Value ($varValue -replace $pattern, '$3') -Force

         Write-Host $varName '=' ($varValue -replace $pattern, '$3')
        }
  }
}

