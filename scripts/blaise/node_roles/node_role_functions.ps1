. "$PSScriptRoot\..\..\logging_functions.ps1"

function Get-CurrentNodeRoles {
    try {
        $output = & C:\Blaise5\Bin\ServerManager -lsr | Out-String
        return $output
    }
    catch {
        LogError("Failed to run ServerManager")
        LogError("$($_.Exception.Message)")
        LogError("$($_.ScriptStackTrace)")
        return $null
    }
}

function Parse-CurrentNodeRoles {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CurrentRoles
    )

    if ([string]::IsNullOrEmpty($CurrentRoles)) {
        $CurrentRoles = Get-CurrentNodeRoles
        if ([string]::IsNullOrEmpty($CurrentRoles)) { return $null }
    }

    $roleMapping = @{
        'ADMIN'          = 'admin'
        'AUDITTRAIL'     = 'audittrail'
        'CARI'           = 'cari'
        'CASEMANAGEMENT' = 'casemanagement'
        'CATI'           = 'cati'
        'DASHBOARD'      = 'dashboard'
        'DATA'           = 'data'
        'DATAENTRY'      = 'dataentry'
        'EVENT'          = 'event'
        'PUBLISH'        = 'publish'
        'RESOURCE'       = 'resource'
        'SESSION'        = 'session'
        'WEB'            = 'web'
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
    param(
        [string]$roleServerShouldHaveTest = $null
    )
    $roleServerShouldHave = if (![string]::IsNullOrEmpty($roleServerShouldHaveTest)) {
        $roleServerShouldHaveTest
    } else {
        [Environment]::GetEnvironmentVariable("ENV_BLAISE_ROLES", "Machine")
    }
    
    if ([string]::IsNullOrEmpty($roleServerShouldHave)) {
        Write-Host "ENV_BLAISE_ROLES environment variable is not set"
        return $null
    }
    $roles = $roleServerShouldHave.Split(',') | ForEach-Object { $_.Trim() } | Sort-Object
    return $roles -join ','
}

function Check-NodeHasCorrectRoles {
    $requiredRoles = Get-RequiredRoles
    LogInfo("Required node roles: $requiredRoles")
    if ($null -eq $requiredRoles) { return $false }

    $currentRoles = Parse-CurrentNodeRoles
    LogInfo("Current node roles: $currentRoles")
    if ($null -eq $currentRoles) { return $false }

    return $currentRoles -eq $requiredRoles
}
