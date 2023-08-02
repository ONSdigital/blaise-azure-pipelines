BeforeAll {
    . "$PSScriptRoot\mysql_database_setup.ps1"
    . "$PSScriptRoot\..\helpers\data_interface_files.ps1"
}

Describe 'RestartBlaiseRequired' {

    It 'returns true when changes were detected in the configuration settings for the Session Data Interface' {
        # Arrange
        $configurationSettings =  @"
-----------------------------------------------------
|              Configuration settings               |
-----------------------------------------------------
| Setting                 | Value            | Used |
-----------------------------------------------------
| Session Data Interface  |                  | Yes  |
-----------------------------------------------------
"@ 
        Mock ListOfConfigurationSettings { return $configurationSettings }
        $filePath = "D:\Blaise5\Settings\sessiondb.bsdi"

        # Act
        $result = RestartBlaiseRequired -filePath $filePath

        # Assert
        $result | Should -Be $true
    }
}