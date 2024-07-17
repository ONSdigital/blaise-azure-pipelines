param ([string]$RuleName, [string[]]$Inbound_Ports, [string[]]$Outbound_Ports)

function SetFirewallRules
{
    param (
        [string]$RuleName,
        [string[]] $Ports,
        [string] $Direction,
        [string] $PortType
    )
    if ($PortType -eq "LocalPort")
    {
        New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -LocalPort $Ports -Protocol TCP -Action Allow
        Write-Host "$RuleName $Direction firewall rule created with the following local ports: $Ports"
    }
    if ($PortType -eq "RemotePort")
    {
        New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -RemotePort $Ports -Protocol TCP -Action Allow
        Write-Host "$RuleName $Direction firewall rule created with the following remote ports: $Ports"
    }
}

function PortsMatch {
    param (
        [string]$RuleName,
        [string[]] $Ports,
        [string] $Direction,
        [string] $PortType
    )
    $portsString = [string]$Ports
    $portTypeString = [string]$PortType
    Get-NetFirewallRule -DisplayName $RuleName | Where-Object -Property Direction -EQ $Direction | Get-NetFirewallPortFilter | ForEach-Object{
        if ([string]$_.$portTypeString -eq [string]$portsString)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}
try {
    if (Get-NetFirewallRule -DisplayName "$RuleName" -ErrorAction SilentlyContinue)
    {
        $LocalPortExists = PortsMatch -RuleName:"$RuleName" -Ports:$Inbound_Ports -Direction:"Inbound" -PortType:"LocalPort"
        $RemotePortExists = PortsMatch -RuleName:"$RuleName" -Ports:$Outbound_Ports -Direction:"Outbound" -PortType:"RemotePort"

        if (-Not $RemotePortExists -or -Not $LocalPortExists)
        {
            Remove-NetFirewallRule -DisplayName "$RuleName"
            SetFirewallRules -RuleName:"$RuleName" -Direction:"Inbound" -Ports:$Inbound_Ports -PortType:"LocalPort"
            SetFirewallRules -RuleName:"$RuleName" -Direction:"Outbound" -Ports:$Outbound_Ports -PortType:"RemotePort"
        }
        else
        {
            Write-Host "Firewall rules already exist"
        }
    }
    else
    {
        Write-Host "Firewall rules missing, creating them..."
        SetFirewallRules -RuleName:"$RuleName" -Direction:"Inbound" -Ports:$Inbound_Ports -PortType:"LocalPort"
        SetFirewallRules -RuleName:"$RuleName" -Direction:"Outbound" -Ports:$Outbound_Ports -PortType:"RemotePort"
    }
}
catch {
    Write-Host "Unable to setup firewall rules"
    Write-Host $_.ScriptStackTrace
    exit 1
}
