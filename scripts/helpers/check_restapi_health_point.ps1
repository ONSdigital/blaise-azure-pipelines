try {
    $response = Invoke-WebRequest $env:TESTING_URL -Method Get -UseBasicParsing
    $hostname = hostname

    if ($response.StatusCode -eq 200)
    {
        Write-Output "$hostname responded with status code 200"
    }
    else
    {
        Write-Output "$hostname has issues: $($response.StatusCode)"
        exit 1
    }
}
catch {
    Write-Output "Rest Api has responded with an OK status, error: $($_.Exception.Message)"
    exit 1
}
