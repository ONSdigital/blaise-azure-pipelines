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
        $varDefinition = $variable.Definition
        $pattern = "^(.*?)$([regex]::Escape($varName))(.?=)(.*)"
        $varValue = ($varDefinition -replace $pattern, '$3')

        if ($variable.Name -Like "BLAISE_*")
        {
            New-Variable -Scope script -Name ($varName) -Value $varValue -Force
            Write-Output "Script Env Var - $varName = $varValue"
        }

        if ($variable.Name -Like "ENV_*")
        {
            [System.Environment]::SetEnvironmentVariable($varName, ($varValue), [System.EnvironmentVariableTarget]::Machine)
            Write-Output "System Env Var - $varName = $varValue"
        }
    }
}

Write-Output "Setting up script and system environment variables..."
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
