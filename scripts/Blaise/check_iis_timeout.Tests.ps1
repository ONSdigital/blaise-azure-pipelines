BeforeAll {. "$PSScriptRoot\check_iis_timeouts.ps1" "$PSScriptRoot\increase_iis_timeouts.ps1"}

describe "timeoutIsSetCorrectly" {
    BeforeEach{
        Mock currentTimeoutValues{ return "00:00:00", "00:00:00" }
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
describe "setTimeoutValues" {
    BeforeEach{
        Mock Restart-WebAppPool {
            # This mock function will be called instead of the actual Restart-WebAppPool
        }
    }
    It "Restarts the app pool when timeouts have been set/changed" {
        $currentSessionStateTimeout = "00:15:00"
        $currentIdleTimeout = "09:00:00"
        Mock currentTimeoutValues { return $currentSessionStateTimeout, $currentIdleTimeout}
        setTimeoutValues
        Assert-MockCalled Restart-WebAppPool -Exactly 1
    }
    It "Doesn't restart the app pool when timeouts are already set correctly" {
        $currentSessionStateTimeout = "08:00:00"
        $currentIdleTimeout = "08:00:00"
        Mock currentTimeoutValues { return $currentSessionStateTimeout, $currentIdleTimeout}
        setTimeoutValues
        Assert-MockCalled Restart-WebAppPool -Exactly 0
    }
}

