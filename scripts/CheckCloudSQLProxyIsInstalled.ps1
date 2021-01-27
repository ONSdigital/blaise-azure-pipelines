$response = Test-NetConnection -computername 127.0.0.1 -p 3306

$result = "##vso[task.setvariable variable=SQLProxyInstalled;isOutput=true]" + $response.TcpTestSucceeded

Write-Host $result
