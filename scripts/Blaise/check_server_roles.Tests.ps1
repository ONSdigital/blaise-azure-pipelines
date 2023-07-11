BeforeAll {. "$PSScriptRoot\check_server_roles.ps1"}

Describe 'Parse current Node roles' {
    It 'returns a correctly ordered comma separated list of roles' {
        $CurrentRoles =  @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| ADMIN      | 8031 | http    |
| AUDITTRAIL | 8033 | http    |
| CATI       | 8033 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail,cati"
        $result = ParseCurrentNodeRoles($CurrentRoles)
        $result | Should -Be $expected_output
    }

    It 'returns a correctly ordered comma separated list of roles in the correct order' {
        $CurrentRoles =  @"
-----------------------------
|        Server Roles         |
-----------------------------
| Name       | Port | Binding |
-----------------------------
| AUDITTRAIL | 8033 | http    |
| ADMIN      | 8031 | http    |
| CATI       | 8033 | http    |
-----------------------------
"@
        $expected_output = "admin,audittrail,cati"
        $result = ParseCurrentNodeRoles($CurrentRoles)
        $result | Should -Be $expected_output
    }
}