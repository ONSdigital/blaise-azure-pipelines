Write-Host "Hello Nik"

function GetMetadataVariables1
{
  $variablesFromMetadata = Invoke-RestMethod http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=true -Headers @{ "Metadata-Flavor" = "Google" }
  return $variablesFromMetadata | Get-Member -MemberType NoteProperty
}

function CreateVariables1($variableList)
{

  foreach ($variable in $variableList)
  {
      if ($variable.Name -Like "BLAISE_*")
      {
        $varName = $variable.Name
        $varValue = $variable.Definition

        $pattern = "^(.*?)$([regex]::Escape($varName) )(.?=)(.*)"

         New-Variable -Scope script -Name ($varName) -Value ($varValue -replace $pattern, '$3')

         Write-Host $varName '=' ($varValue -replace $pattern, '$3')
         
         $varValue = ($varValue -replace $pattern, '$3')
         
         Write-Host "##vso[task.setvariable variable=$varName;]$varValue"
        }
  }
}

Write-Host "Setting up script and system variables..."
$metadataVariables = GetMetadataVariables1
CreateVariables1($metadataVariables)
Write-Host "##vso[task.setvariable variable=fruit]Apple"
Write-Host "Fruit is $(env:FRUIT)"
