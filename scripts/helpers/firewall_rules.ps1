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
        Write-Output "$RuleName $Direction firewall rule created with the following Local ports: $Ports"
    }
    if ($PortType -eq "RemotePort")
    {
        New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -RemotePort $Ports -Protocol TCP -Action Allow
        Write-Output "$RuleName $Direction firewall rule created with the following Remote ports: $Ports"
    }
}

function PortsMatch {
    param (
        [string]$RuleName,
        [string[]] $Ports,
        [string] $Direction,
        [string] $PortType
    )
    Get-NetFirewallRule -DisplayName $RuleName | Where-Object -Property Direction -EQ $Direction | Get-NetFirewallPortFilter | ForEach-Object{

        if ([string]$_.$PortType -eq [string]$Ports)
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
            Write-Output "Firewall rules already exist"
        }
    }
    else
    {
        Write-Output "No Firewall rule exists, Creating them"
        SetFirewallRules -RuleName:"$RuleName" -Direction:"Inbound" -Ports:$Inbound_Ports -PortType:"LocalPort"
        SetFirewallRules -RuleName:"$RuleName" -Direction:"Outbound" -Ports:$Outbound_Ports -PortType:"RemotePort"
    }
}
catch {
    Write-Output "Unable to setup firewall rules"
    Write-Output $_.ScriptStackTrace
    exit 1
}
