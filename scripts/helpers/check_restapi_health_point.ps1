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
    Write-Host "****** Error Details ******"
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
    Write-Host "Stack Trace: $($_.Exception.StackTrace)"
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)"
    }
    Write-Host "****** End Error Details ******"
    Write-Host "Rest Api has responded with an OK status, error: $($_.Exception.Message)"
    exit 1
}
