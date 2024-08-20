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

        if ($variable.Name -Like "ENV_*") {
            if ($varValue.StartsWith("projects/")) { 
                if (-not (Get-Module -ListAvailable -Name SecretManagement)) {
                    Install-Module -Name SecretManagement -AcceptLicense
                }

                try {
                    $secretValue = Get-Secret -SecretId $varValue -Version 'latest'
                    [System.Environment]::SetEnvironmentVariable($varName, $secretValue, [System.EnvironmentVariableTarget]::Machine)
                    LogInfo("Secret Manager var - $varName = $secretValue")
                }
                catch {
                    LogError("Failed to retrieve secret for $varName - $($_.Exception.Message)")
                }
            } else {
                [System.Environment]::SetEnvironmentVariable($varName, ($varValue), [System.EnvironmentVariableTarget]::Machine)
                LogInfo("System env var - $varName = $varValue")
            }
        } 
    }
}

LogInfo("Updating system (VM) environment variables...")
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
