BeforeAll {. "$PSScriptRoot\check_server_roles.ps1"}

Describe 'Parse current node roles' {
    
    It 'returns a correctly ordered comma separated list of roles' {
        $CurrentRoles =  @"
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
        $result = ParseCurrentNodeRoles($CurrentRoles)
        $result | Should -Be $expected_output
    }

    It 'returns DATA and DATAENTRY roles correctly' {
        $CurrentRoles =  @"
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
        $result = ParseCurrentNodeRoles($CurrentRoles)
        $result | Should -Be $expected_output
    }

    It 'does not return unexpected roles' {
        $CurrentRoles =  @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| ADMIM      | 8031 | http    |
| AUDITTRAIL | 8031 | http    |
| CROISSANT  | 8033 | http    |
| BAGEL      | 8033 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail"
        $result = ParseCurrentNodeRoles($CurrentRoles)
        $result | Should -Be $expected_output
    }

}