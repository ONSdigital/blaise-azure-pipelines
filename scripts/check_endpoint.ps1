. "$PSScriptRoot\logging_functions.ps1"

param(
    [string]$Url = $env:TESTING_URL
)

if (-not $Url) {
    LogInfo("URL not provided, set TESTING_URL env var or pass as parameter")
    exit 1
}

LogInfo("Testing URL: $Url")

try {
    $response = Invoke-WebRequest $Url -Method Get -UseBasicParsing
    $hostname = hostname
    $statusCode = $response.StatusCode

    if ($statusCode -ge 200 -and $statusCode -lt 300) {
        LogInfo("$hostname responded with status code $statusCode")
    }
    else {
        LogInfo("$hostname has issues, status code $statusCode")
        exit 1
    }
}
catch {
    LogError("An error occurred while making the request to $Url")
    LogError("$($_.Exception.Message)")
    LogError("$($_.ScriptStackTrace)")
    exit 1
}