try {
    $response = Invoke-WebRequest $env:TESTING_URL -Method Get -UseBasicParsing
    $hostname = hostname

    if ($response.StatusCode -eq 200)
    {
        Write-Host "$hostname responded with status code 200"
    }
    else
    {
        Write-Host "$hostname has issues: $($response.StatusCode)"
        exit 1
    }
}
catch {
    Write-Host "Rest Api has responded with an OK status, error: $($_.Exception.Message)"
    exit 1
}
