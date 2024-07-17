. "$PSScriptRoot\logging_functions.ps1"

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
            LogInfo("Script env var - $varName = $varValue")
        }

        if ($variable.Name -Like "ENV_*")
        {
            [System.Environment]::SetEnvironmentVariable($varName, ($varValue), [System.EnvironmentVariableTarget]::Machine)
            LogInfo("System env var - $varName = $varValue")
        }
    }
}

LogInfo("Setting up script and system environment variables...")
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
