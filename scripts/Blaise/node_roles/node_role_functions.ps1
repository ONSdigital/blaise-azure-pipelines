function Get-CurrentNodeRoles {
    try {
        $output = & C:\Blaise5\Bin\ServerManager -lsr | Out-String
        return $output
    }
    catch {
        Write-Error "Failed to execute ServerManager: $_"
        return $null
    }
}

function Parse-CurrentNodeRoles {
    param (
        [Parameter(Mandatory=$false)]
        [string]$CurrentRoles
    )

    if ([string]::IsNullOrEmpty($CurrentRoles)) {
        $CurrentRoles = Get-CurrentNodeRoles
        if ([string]::IsNullOrEmpty($CurrentRoles)) { return $null }
    }

    $roleMapping = @{
        'ADMIN' = 'admin'
        'AUDITTRAIL' = 'audittrail'
        'CATI' = 'cati'
        'DATA' = 'data'
        'DATAENTRY' = 'dataentry'
        'DASHBOARD' = 'dashboard'
        'RESOURCE' = 'resource'
        'SESSION' = 'session'
        'WEB' = 'web'
    }

    $roles = @()
    foreach ($line in $CurrentRoles -split "`n") {
        foreach ($key in $roleMapping.Keys) {
            if ($line -match "\b$key\b") {
                $roles += $roleMapping[$key]
            }
        }
    }

    if ($roles.Count -eq 0) { return $null }
    return ($roles | Sort-Object | Select-Object -Unique) -join ','
}

function Get-RequiredRoles {
    $roleServerShouldHave = $env:ENV_BLAISE_ROLES
    if ([string]::IsNullOrEmpty($roleServerShouldHave)) {
        Write-Warning "ENV_BLAISE_ROLES environment variable is not set."
        return $null
    }
    $roles = $roleServerShouldHave.Split(',') | ForEach-Object { $_.Trim() } | Sort-Object
    return $roles -join ','
}

function Check-NodeHasCorrectRoles {
    $requiredRoles = Get-RequiredRoles
    if ($null -eq $requiredRoles) { return $false }

    $currentRoles = Parse-CurrentNodeRoles
    if ($null -eq $currentRoles) { return $false }

    return $currentRoles -eq $requiredRoles
}