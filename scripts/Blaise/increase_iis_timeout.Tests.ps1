BeforeAll {. "$PSScriptRoot\increase_iis_timeout.ps1"}

describe "timeoutIsSetCorrectly" {
    BeforeEach{
        Mock currentTimeoutValues{ return "00:00:00", "00:00:00" }
        $currentSessionStateTimeout, $currentIdleTimeout = currentTimeoutValues
    }
    
    it "should return true if the current timeouts are equal to the expected timeout" {
        currentTimeoutValues
        $expectedTimeout = "00:00:00"
        $currentTimeoutIsSetCorrectly = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout
        $currentTimeoutIsSetCorrectly | should -be  $true
    }
    it "should return false if the current timeout is not equal to the expected timeout" {
        currentTimeoutValues
        $expectedTimeout = "00:00:01"
        $currentTimeoutIsSetCorrectly = timeoutIsSetCorrectly -currentSessionTimeout $currentSessionStateTimeout -currentIdleTimeout $currentIdleTimeout -expectedTimeout $expectedTimeout
        $currentTimeoutIsSetCorrectly | should -be  $false
    }
}
describe "setTimeoutValues" {
    It "Correctly sets session state timeout and restarts when needed" {
        $currentSessionStateTimeout = "00:15:00"
        $currentIdleTimeout = "09:00:00"
        
        Mock currentTimeoutValues { return $currentSessionStateTimeout, $currentIdleTimeout}
        setTimeoutValues 
        $restartNeeded | Should -Be $true
    }

    It "Doesn't restart when timeouts are already set correctly" {
        $currentSessionStateTimeout = "09:00:00"
        $currentIdleTimeout = "09:00:00"
        
        Mock currentTimeoutValues { return $currentSessionStateTimeout, $currentIdleTimeout}
        setTimeoutValues 
        $restartNeeded | Should -Be $false
    }
}

