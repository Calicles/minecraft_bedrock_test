# Diagnostic + correction réseau pour que la Switch voie le serveur en "Parties LAN".
# Se relance tout seul en administrateur si besoin :
#   powershell -ExecutionPolicy Bypass -File scripts\fix-firewall.ps1
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    # Relance automatiquement le script en administrateur (Windows affiche une confirmation)
    Write-Host 'Relance en administrateur...'
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$Root = Split-Path $PSScriptRoot -Parent
$Exe  = Join-Path $Root 'server\bedrock_server.exe'

# 1. Profil réseau : Public -> Privé
Write-Host '== Profil réseau =='
foreach ($p in Get-NetConnectionProfile) {
    Write-Host "  $($p.InterfaceAlias) : $($p.NetworkCategory)"
    if ($p.NetworkCategory -eq 'Public') {
        Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private
        Write-Host "    -> passé en Privé"
    }
}

# 2. Règles de blocage créées si on a cliqué "Annuler" sur l'alerte du pare-feu
Write-Host '== Règles existantes pour bedrock_server.exe =='
$rules = Get-NetFirewallApplicationFilter | Where-Object { $_.Program -like '*bedrock_server.exe' } | Get-NetFirewallRule
foreach ($r in $rules) {
    Write-Host "  $($r.DisplayName) [$($r.Direction) $($r.Action) $($r.Profile)]"
    if ($r.Action -eq 'Block') {
        Remove-NetFirewallRule -Name $r.Name
        Write-Host "    -> règle de blocage supprimée"
    }
}

# 3. Règles d'autorisation (port UDP 19132/19133 + programme)
Write-Host '== Ajout des règles Minecraft BDS =='
Get-NetFirewallRule -DisplayName 'Minecraft BDS*' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'Minecraft BDS (UDP 19132-19133)' -Direction Inbound -Protocol UDP `
    -LocalPort 19132,19133 -Action Allow -Profile Any | Out-Null
if (Test-Path $Exe) {
    New-NetFirewallRule -DisplayName 'Minecraft BDS (programme)' -Direction Inbound -Program $Exe `
        -Action Allow -Profile Any | Out-Null
}
Write-Host '  OK'

# 4. Le serveur écoute-t-il ?
Write-Host '== Port 19132 =='
$listen = Get-NetUDPEndpoint -LocalPort 19132 -ErrorAction SilentlyContinue
if ($listen) {
    Write-Host '  Le serveur écoute bien sur le port 19132.'
} else {
    Write-Host '  Rien n''écoute sur 19132 : lance le serveur (scripts\install-server.ps1) puis réessaie.'
}

Write-Host ''
Write-Host 'Adresse(s) IP de ce PC :'
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
    ForEach-Object { Write-Host "  $($_.IPAddress)  ($($_.InterfaceAlias))" }
Write-Host ''
Write-Host 'Redémarre le serveur, puis regarde à nouveau dans Amis > Parties LAN sur la Switch.'
