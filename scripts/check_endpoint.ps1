param(
    [string]$Url = $env:TESTING_URL
)

if (-not $Url) {
    Write-Host "URL not provided, set TESTING_URL env var or pass as parameter"
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
        Write-Host "$hostname has issues, status code $statusCode"
        exit 1
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Host "An error occurred while making the request to $Url - $errorMessage"
    exit 1
}