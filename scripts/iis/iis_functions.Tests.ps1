BeforeAll {
    Mock Get-Module { @{ Name = "WebAdministration" } }
    Mock Import-Module { }
    . "$PSScriptRoot\iis_functions.ps1"
    Mock LogInfo { }
    Mock LogError { }
}

describe "timeoutIsSetCorrectly" {
    BeforeEach {
        Mock currentTimeoutValues { return "00:00:00", "00:00:00" }
        $currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues
    }
    it "should return true if the current timeouts are equal to the expected timeout" {
        currentTimeoutValues
        $expectedTimeout = "00:00:00"
        $currentTimeoutIsSetCorrectly = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout
        $currentTimeoutIsSetCorrectly | Should -Be $true
    }
    it "should return false if the current timeouts are not equal to the expected timeout" {
        currentTimeoutValues
        $expectedTimeout = "00:00:01"
        $currentTimeoutIsSetCorrectly = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout
        $currentTimeoutIsSetCorrectly | Should -Be $false
    }
}

describe "AddRewriteRule" {
    BeforeEach {
        Mock Test-Path { $true }
        Mock Add-WebConfigurationProperty { }
        Mock Set-WebConfigurationProperty { }
        Mock Get-WebConfigurationProperty { $null }
    }

    it "should create a missing rule and apply expected properties" {
        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and $name -eq "."
        } { $null }

        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and $name -eq "preCondition"
        } { $null }

        AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://survey.example.com" -rule "https?://blaise-gusty-mgmt[^/]*"

        Assert-MockCalled Add-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules" -and $name -eq "."
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/match" -and
            $name -eq "pattern" -and
            $value -eq "https?://blaise-gusty-mgmt[^/]*"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/action" -and
            $name -eq "type" -and
            $value -eq "Rewrite"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/action" -and
            $name -eq "value" -and
            $value -eq "https://survey.example.com"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and
            $name -eq "preCondition" -and
            $value -eq "NoCompression"
        }
    }

    it "should reconcile pattern and action for an existing rule" {
        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and $name -eq "."
        } { @{ name = "Blaise mgmt" } }

        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and $name -eq "preCondition"
        } { "NoCompression" }

        AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://survey.example.com" -rule "https?://blaise-gusty-mgmt[^/]*"

        Assert-MockCalled Add-WebConfigurationProperty -Times 0 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules" -and $name -eq "."
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/match" -and
            $name -eq "pattern" -and
            $value -eq "https?://blaise-gusty-mgmt[^/]*"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/action" -and
            $name -eq "type" -and
            $value -eq "Rewrite"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']/action" -and
            $name -eq "value" -and
            $value -eq "https://survey.example.com"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 0 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt']" -and
            $name -eq "preCondition"
        }
    }

    it "should skip rewrite configuration when the IIS site does not exist" {
        Mock Test-Path { $false }

        AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt" -serverName "https://survey.example.com" -rule "https?://blaise-gusty-mgmt[^/]*"

        Assert-MockCalled Add-WebConfigurationProperty -Times 0
        Assert-MockCalled Set-WebConfigurationProperty -Times 0
    }

    it "should set response header match and clear precondition when requested" {
        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt location header']" -and $name -eq "."
        } { @{ name = "Blaise mgmt location header" } }

        Mock Get-WebConfigurationProperty -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt location header']" -and $name -eq "preCondition"
        } { "NoCompression" }

        AddRewriteRule -siteName "Blaise" -ruleName "Blaise mgmt location header" -serverName "https://survey.example.com{R:2}" -rule "^https?://blaise-gusty-mgmt(:\\d+)?(.*)$" -serverVariable "RESPONSE_LOCATION" -preCondition ""

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt location header']/match" -and
            $name -eq "serverVariable" -and
            $value -eq "RESPONSE_LOCATION"
        }

        Assert-MockCalled Set-WebConfigurationProperty -Times 1 -Exactly -ParameterFilter {
            $filter -eq "system.webServer/rewrite/outboundRules/rule[@name='Blaise mgmt location header']" -and
            $name -eq "preCondition" -and
            $value -eq ""
        }
    }
}
