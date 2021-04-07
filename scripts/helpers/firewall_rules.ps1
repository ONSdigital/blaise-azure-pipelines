param ($inbound_ports, $outbound_ports)

Write-Host "Inbound ports $inbound_ports, outbound ports $outbound_ports"
New-NetFirewallRule -DisplayName "Blaise" -Direction Inbound -LocalPort 80, 443, $inbound_ports -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Blaise" -Direction Outbound -RemotePort 80, 443, $outbound_ports -Protocol TCP -Action Allow

