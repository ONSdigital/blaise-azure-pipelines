BeforeAll { . "$PSScriptRoot\iis_timeout_functions.ps1" }

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
