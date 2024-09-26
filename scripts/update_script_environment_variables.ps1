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

        if ($variable.Name -Like "BLAISE_*" -and $varValue -Like "projects/*/secrets/*") {

            $parts = $varValue -split "/"
            $projectId = $parts[1]
            $secret = $parts[3]

            $secretValue = & gcloud secrets versions access latest --secret=$secret --project=$projectId

            New-Variable -Scope script -Name ($varName) -Value $secretValue -Force
            LogInfo("BENNY2 Secret Update Script env var - $varName = $secretValue")
        }
        elseif ($variable.Name -Like "BLAISE_*") {
            New-Variable -Scope script -Name ($varName) -Value $varValue -Force
            LogInfo("Script env var - $varName = $varValue")
        }
    }
}

LogInfo("Updating script environment variables...")
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
