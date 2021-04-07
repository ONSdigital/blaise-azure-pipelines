param ($inbound_ports, $outbound_ports)

$InboundPorts = $inbound_ports -split ' ' -join ','
$OutboundPorts = $outbound_ports -split ' ' -join ','

Write-Host "Inbound ports $InboundPorts, outbound ports $OutboundPorts"
New-NetFirewallRule -DisplayName "Blaise" -Direction Inbound -LocalPort 80, 443, $InboundPorts -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Blaise" -Direction Outbound -RemotePort 80, 443, $OutboundPorts -Protocol TCP -Action Allow

