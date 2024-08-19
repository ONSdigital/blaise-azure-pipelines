. "$PSScriptRoot\logging_functions.ps1"

function GetMetadataVariables {
    # $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
    # return $variablesFromMetadata | Get-Member -MemberType NoteProperty

    $variableGroupId = $env:PARAMETERS.VarGroup.Id
    LogInfo("Variable group ID: $variableGroupId")
    # $variableGroup = Get-AzDevOpsVariableGroupVsts -Id $variableGroupId 
    # $variableGroupName = $variableGroup.name

    # LogInfo("Variable group name: $variableGroupName")
    # Get variable names and values from the environment variables
    $variables = Get-ChildItem Env: | Where-Object { $_.Name -like "$variableGroupName.*" } | ForEach-Object {
        $variableName = $_.Name.Substring($variableGroupName.Length + 1) # Remove the variable group prefix
        @{ $variableName = $_.Value }
    }

    return $variables.Keys
}

function CreateVariables($variableList) {
    foreach ($variable in $variableList) {
        $varName = $variable.Name
        $varDefinition = $variable.Definition
        $pattern = "^(.*?)$([regex]::Escape($varName))(.?=)(.*)"
        $varValue = ($varDefinition -replace $pattern, '$3')

        if ($variable.Name -Like "BLAISE_*") {
            New-Variable -Scope script -Name ($varName) -Value $varValue -Force
            LogInfo("Script env var - $varName = $varValue")
        }
    }
}

LogInfo("Updating script environment variables...")
$metadataVariables = GetMetadataVariables
CreateVariables($metadataVariables)
