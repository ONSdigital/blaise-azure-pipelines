. "$PSScriptRoot\logging_functions.ps1"

function GetMetadataVariables {
    $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
    return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables($variableList) {
    foreach ($variable in $variableList) {
        $varName = $variable.Name
        $varDefinition = $variable.Definition
        $pattern = "^(.*?)$([regex]::Escape($varName))(.?=)(.*)"
        $varValue = ($varDefinition -replace $pattern, '$3')

        if ($variable.Name -Like "ENV_*" -and $varValue -Like "projects/*/secrets/*") {

            $parts = $varValue -split "/"
            $secret = $parts[3]

            $secretValue = & gcloud secrets versions access latest --secret=$secret

            [System.Environment]::SetEnvironmentVariable($varName, ($secretValue), [System.EnvironmentVariableTarget]::Machine)
            LogInfo("BENNY1 Secret Update System Environment Variables - $varName = $secretValue")
        }
        elseif ($variable.Name -Like "ENV_*") {
            [System.Environment]::SetEnvironmentVariable($varName, ($varValue), [System.EnvironmentVariableTarget]::Machine)
            LogInfo("System env var - $varName = $varValue")
        }
    }
}

LogInfo("Updating system (VM) environment variables...")
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
