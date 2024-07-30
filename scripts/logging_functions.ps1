$source = "AzureDevOpsPipeline"

function LogInfo {
    param (
        $message
    )

    if ($IsWindows) {
        CreateSourceIfNotExists($source)
        Write-Host "Information: $message"
        Write-EventLog -LogName "Application" -Source $source -EventId 3001 -EntryType Information -Message "$($source): $message"
    } else {
        Write-Host "Information: $message"
    }
}

function LogWarning {
    param (
        $message
    )

    if ($IsWindows) {
        CreateSourceIfNotExists($source)
        Write-Host "Warning: $message"
        Write-EventLog -LogName "Application" -Source $source -EventId 3001 -EntryType Warning -Message "$($source): $message"
    } else {
        Write-Host "Warning: $message"
    }
}

function LogError {
    param (
        $message
    )

    if ($IsWindows) {
        CreateSourceIfNotExists($source)
        Write-Host "Error: $message"
        Write-EventLog -LogName "Application" -Source $source -EventId 3001 -EntryType Error -Message "$($source): $message"
    } else {
        Write-Host "Error: $message"
    }
}

function CreateSourceIfNotExists {
    param (
        $dataSource
    )

    if ($IsWindows -and -Not [System.Diagnostics.EventLog]::SourceExists($dataSource)) {
        New-EventLog -LogName Application -Source $dataSource
    }
}