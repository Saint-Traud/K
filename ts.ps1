$ErrorActionPreference = 'Stop'
$ts = "$env:ProgramW6432\Tailscale\tailscaled.exe"
if (-not (Test-Path $ts)) { throw "tailscaled.exe not found at $ts - aborting before the block goes on" }

# (re)create the allow rules without duplicating them on re-runs
'TS killswitch: tunnel','TS killswitch: tailscaled' | ForEach-Object {
    Remove-NetFirewallRule -DisplayName $_ -ErrorAction SilentlyContinue
}
New-NetFirewallRule -DisplayName 'TS killswitch: tunnel'     -Direction Outbound -InterfaceAlias 'Tailscale' -Action Allow | Out-Null
New-NetFirewallRule -DisplayName 'TS killswitch: tailscaled' -Direction Outbound -Program $ts -Action Allow | Out-Null

# DNS leak hardening (on non-English Windows use: -Name CoreNet-DNS-Out-UDP)
Disable-NetFirewallRule -DisplayName 'Core Networking - DNS (UDP-Out)' -ErrorAction SilentlyContinue

# the actual block, which has to come last
Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block

Get-NetFirewallProfile -PolicyStore ActiveStore | Select-Object Name, Enabled, DefaultOutboundAction
