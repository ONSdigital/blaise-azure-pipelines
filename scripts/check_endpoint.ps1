param(
    [string]$Url = $env:TESTING_URL
)

if (-not $Url) {
    Write-Host "URL is not provided. Please set TESTING_URL environment variable or pass the URL as a parameter."
    exit 1
}

Write-Host "Testing URL: $Url"

try {
    $response = Invoke-WebRequest $Url -Method Get -UseBasicParsing
    $hostname = hostname
    $statusCode = $response.StatusCode

    if ($statusCode -ge 200 -and $statusCode -lt 300) {
        Write-Host "$hostname responded with status code $statusCode"
    }
    else {
        Write-Host "$hostname has issues: Status code $statusCode"
        exit 1
    }
}
catch {
    Write-Host "An error occurred while making the request to $Url: ${$_.Exception.Message}"
    exit 1
}