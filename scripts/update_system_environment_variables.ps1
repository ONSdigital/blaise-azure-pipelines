. "$PSScriptRoot\logging_functions.ps1"

function GetMetadataVariables {
    $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
    return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function UpdateEnvironmentalVariable {

    param (
        [string]$varName,
        [string]$secretValue,
        [string]$secret
    )

    $envValue = [System.Environment]::GetEnvironmentVariable($varName, [System.EnvironmentVariableTarget]::Machine)

    if ($envValue -eq $secretValue) {
        Write-Host "Values are the same, no need to update secrets."
    }
    elseif ($envValue -eq "" -or $null -eq $envValue) {
        Write-Host "Environmental Variable not set, setting to secret value."
        [System.Environment]::SetEnvironmentVariable($varName, ($secretValue), [System.EnvironmentVariableTarget]::Machine)
    }
    elseif ($envValue -ne "" -and $null -ne $envValue -and $secretValue -ne "" -and $null -ne $secretValue) {
        # If Environmental values are updated, secret values should be updated
        Write-Host "Environmental Variable is set to a different value than secret, updating secret value"

        $tempFile = New-TemporaryFile

        # Create a UTF8 encoding without BOM
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)

        # Write the content to the file using the specified encoding
        [System.IO.File]::WriteAllText($tempFile, $envValue, $utf8NoBomEncoding)

        # Add the secret using gcloud
        & gcloud secrets versions add $secret --data-file=$tempFile

        # Clean up the temporary file
        Remove-Item $tempFile
    }
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

            UpdateEnvironmentalVariable $variable.Name $secretValue $secret
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
