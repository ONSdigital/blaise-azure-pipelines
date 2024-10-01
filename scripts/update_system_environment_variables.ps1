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

    Write-Host "UpdateEnvironmentalVariables Called with following values"
    Write-Host "varName = $varName"
    Write-Host "secretValue = $secretValue"
    Write-Host "secret = $secret"

    $envValue = [System.Environment]::GetEnvironmentVariable($varName, [System.EnvironmentVariableTarget]::Machine)

    Write-Host "Retrieved the following value from Environmental Variables"
    Write-Host "envValue = $envValue"

    if ($envValue -eq $secretValue) {
        Write-Host  "Values are the same, doing nothing"
    }
    elseif ($envValue -eq "" -or $null -eq $envValue) {
        Write-Host "Environmental Variable not set, so using Secret value"
        [System.Environment]::SetEnvironmentVariable($varName, ($secretValue), [System.EnvironmentVariableTarget]::Machine)
    }
    elseif ($envValue -ne "" -and $null -ne $envValue -and $secretValue -ne "" -and $null -ne $secretValue) {
        # This is for environments that have been previously set up, so the secret values should remain the same
        Write-Host "Environmental Variable is set to a different value than Secret, Creating new secret version"
        # echo -n $envValue | gcloud secrets versions add $secret --data-file=-  
        $envValue = $envValue -replace "^\uFEFF", ""
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::Write($envValue) | gcloud secrets versions add $secret --data-file=-
    } 
    elseif ($envValue -ne "" -and $null -ne $envValue) {
        # Secret value must be empty at this stage, but Environmental variable is set.
        Write-Output "Environmental Variable is set but there is no value for the secret value"
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

            Write-Host "Calling gcloud with secret of '$secret'"

            $secretValue = & gcloud secrets versions access latest --secret=$secret

            Write-Host "After gcloud call retrieved secretValue of '$secretValue'"

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
