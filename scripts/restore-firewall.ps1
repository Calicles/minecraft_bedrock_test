# Annule les règles ajoutées par fix-firewall.ps1 (à lancer quand tu as fini de tester).
# Se relance tout seul en administrateur si besoin :
#   powershell -ExecutionPolicy Bypass -File scripts\restore-firewall.ps1
# Option -Public : repasse aussi le réseau en profil "Public".
param([switch]$Public)
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Relance en administrateur...'
    $extra = if ($Public) { ' -Public' } else { '' }
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"$extra"
    exit
}

Write-Host '== Suppression des règles Minecraft BDS =='
$rules = @(Get-NetFirewallRule -DisplayName 'Minecraft BDS*' -ErrorAction SilentlyContinue)
$rules += @(Get-NetFirewallApplicationFilter | Where-Object { $_.Program -like '*bedrock_server.exe' } | Get-NetFirewallRule)
$rules | Where-Object { $_ } | Sort-Object Name -Unique | ForEach-Object {
    Write-Host "  $($_.DisplayName)"
    Remove-NetFirewallRule -Name $_.Name
}
if (-not $rules) { Write-Host '  Aucune règle trouvée.' }

if ($Public) {
    Write-Host '== Profil réseau -> Public =='
    Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Private' } | ForEach-Object {
        Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Public
        Write-Host "  $($_.InterfaceAlias) : Public"
    }
}

Write-Host ''
Write-Host 'Terminé. Pour tester à nouveau, relance scripts\fix-firewall.ps1.'
