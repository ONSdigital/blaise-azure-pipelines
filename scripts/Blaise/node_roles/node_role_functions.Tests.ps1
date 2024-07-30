BeforeAll { 
    . "$PSScriptRoot\node_role_functions.ps1"
    
    # Mock Get-CurrentNodeRoles
    Mock Get-CurrentNodeRoles {
        return @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| DATA       | 8031 | http    |
| ADMIN      | 8033 | http    |
-----------------------------
"@
    }
    
    # Mock $env:ENV_BLAISE_ROLES
    $env:ENV_BLAISE_ROLES = "web,data,admin"
}

Describe 'Parse-CurrentNodeRoles' {
    It 'returns a correctly ordered comma-separated list of roles' {
        $CurrentRoles = @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| DATA       | 8031 | http    |
| AUDITTRAIL | 8031 | http    |
| CATI       | 8033 | http    |
| ADMIN      | 8033 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail,cati,data"
        $result = Parse-CurrentNodeRoles -CurrentRoles $CurrentRoles
        $result | Should -Be $expected_output
    }

    It 'returns DATA and DATAENTRY roles correctly' {
        $CurrentRoles = @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| DATA       | 8031 | http    |
| AUDITTRAIL | 8031 | http    |
| CATI       | 8033 | http    |
| ADMIN      | 8033 | http    |
| DATAENTRY  | 8031 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail,cati,data,dataentry"
        $result = Parse-CurrentNodeRoles -CurrentRoles $CurrentRoles
        $result | Should -Be $expected_output
    }

    It 'does not return unexpected roles' {
        $CurrentRoles = @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| ADMIN      | 8031 | http    |
| AUDITTRAIL | 8031 | http    |
| CROISSANT  | 8033 | http    |
| BAGEL      | 8033 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail"
        $result = Parse-CurrentNodeRoles -CurrentRoles $CurrentRoles
        $result | Should -Be $expected_output
    }

    It 'handles empty input correctly' {
        Mock Get-CurrentNodeRoles { return "" }
        $result = Parse-CurrentNodeRoles -CurrentRoles ""
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Get-RequiredRoles' {
    It 'returns sorted, comma-separated roles from environment variable' {
        $result = Get-RequiredRoles -roleServerShouldHaveTest "web,data,admin"
        Write-Host "Result: $result"
        $result | Should -Be "admin,data,web"
    }

    It 'returns null when environment variable is not set' {
        $result = Get-RequiredRoles -roleServerShouldHaveTest ""
        Write-Host "Result: $result"
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Check-NodeHasCorrectRoles' {
    It 'returns true when current roles match required roles' {
        Mock Get-RequiredRoles { return "admin,data,web" }
        Mock Parse-CurrentNodeRoles { return "admin,data,web" }
        $result = Check-NodeHasCorrectRoles
        $result | Should -BeTrue
    }

    It 'returns false when current roles do not match required roles' {
        Mock Get-RequiredRoles { return "admin,data,web" }
        Mock Parse-CurrentNodeRoles { return "admin,data" }
        $result = Check-NodeHasCorrectRoles
        $result | Should -BeFalse
    }

    It 'returns false when required roles cannot be retrieved' {
        Mock Get-RequiredRoles { return $null }
        $result = Check-NodeHasCorrectRoles
        $result | Should -BeFalse
    }

    It 'returns false when current roles cannot be parsed' {
        Mock Get-RequiredRoles { return "admin,data,web" }
        Mock Parse-CurrentNodeRoles { return $null }
        $result = Check-NodeHasCorrectRoles
        $result | Should -BeFalse
    }
}
