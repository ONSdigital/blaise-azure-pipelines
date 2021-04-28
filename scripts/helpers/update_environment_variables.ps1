function GetMetadataVariables
{
  $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
  return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables($variableList)
{
    foreach ($variable in $variableList)
    {
        $varName = $variable.Name
        $varValue = $variable.Definition
        $pattern = "^(.*?)$([regex]::Escape($varName) )(.?=)(.*)"

        if ($variable.Name -Like "BLAISE_*")
        {
            New-Variable -Scope script -Name ($varName) -Value ($varValue -replace $pattern, '$3') -Force

            Write-Host $varName '=' ($varValue -replace $pattern, '$3')
        }

        if ($variable.Name -Like "ENV_*")
        {
            [System.Environment]::SetEnvironmentVariable($varName, ($varValue -replace $pattern, '$3'), [System.EnvironmentVariableTarget]::Machine)
                Write-Host "Env Var   : $varName = $( $varValue -replace $pattern, '$3' )"
        }
    }
}

Write-Host "Setting up script and system variables..."
    $metadataVariables = GetMetadataVariables
    CreateVariables($metadataVariables)