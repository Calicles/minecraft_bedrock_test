# Installe (si besoin) le Bedrock Dedicated Server dans .\server,
# y déploie mon_addon_BP / mon_addon_RP, puis lance le serveur.
# Relancer le script après chaque modification de l'addon pour le redéployer.
#
# Usage :
#   powershell -ExecutionPolicy Bypass -File scripts\install-server.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\install-server.ps1 -ZipPath C:\chemin\bedrock-server-x.y.z.zip
#   powershell -ExecutionPolicy Bypass -File scripts\install-server.ps1 -NoStart
param(
    [string]$ZipPath,
    [switch]$NoStart
)
$ErrorActionPreference = 'Stop'

$Root      = Split-Path $PSScriptRoot -Parent
$ServerDir = Join-Path $Root 'server'
$Packs     = @(
    @{ Dir = 'mon_addon_BP'; Target = 'behavior_packs'; WorldFile = 'world_behavior_packs.json' },
    @{ Dir = 'mon_addon_RP'; Target = 'resource_packs'; WorldFile = 'world_resource_packs.json' }
)

function Write-Utf8NoBom($Path, $Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $false))
}

# 1. Téléchargement / extraction du serveur
if (-not (Test-Path (Join-Path $ServerDir 'bedrock_server.exe'))) {
    if (-not $ZipPath) {
        Write-Host 'Recherche de la dernière version du Bedrock Dedicated Server...'
        $url = $null
        try {
            $links = Invoke-RestMethod 'https://net-secondary.web.minecraft-services.net/api/v1.0/download/links'
            $url = ($links.result.links | Where-Object { $_.downloadType -eq 'serverBedrockWindows' }).downloadUrl
        } catch { }
        if (-not $url) {
            throw "Lien de téléchargement introuvable. Télécharge le zip Windows sur https://www.minecraft.net/download/server/bedrock puis relance avec -ZipPath <chemin du zip>."
        }
        $ZipPath = Join-Path $env:TEMP 'bedrock-server.zip'
        Write-Host "Téléchargement de $url"
        Invoke-WebRequest $url -OutFile $ZipPath -UserAgent 'Mozilla/5.0'
    }
    Write-Host "Extraction dans $ServerDir"
    Expand-Archive $ZipPath $ServerDir -Force
}

# 2. Réglages de server.properties
$propsPath = Join-Path $ServerDir 'server.properties'
$props = Get-Content $propsPath
$wanted = [ordered]@{
    'gamemode'             = 'creative'
    'allow-cheats'         = 'true'
    'texturepack-required' = 'true'
    'content-log-file-enabled' = 'true'
    'enable-lan-visibility' = 'true'
    'allow-list'           = 'false'
}
foreach ($key in $wanted.Keys) {
    if ($props -match "^$key=") {
        $props = $props -replace "^$key=.*", "$key=$($wanted[$key])"
    } else {
        $props += "$key=$($wanted[$key])"
    }
}
Write-Utf8NoBom $propsPath (($props -join "`n") + "`n")
$levelName = (($props | Where-Object { $_ -match '^level-name=' }) -replace '^level-name=', '').Trim()

# 3. Copie des packs + activation sur le monde
$worldDir = Join-Path $ServerDir "worlds\$levelName"
New-Item -ItemType Directory -Force $worldDir | Out-Null
foreach ($p in $Packs) {
    $src = Join-Path $Root $p.Dir
    $dst = Join-Path $ServerDir "$($p.Target)\$($p.Dir)"
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $src $dst -Recurse

    $manifest = Get-Content (Join-Path $src 'manifest.json') -Raw | ConvertFrom-Json
    $uuid    = $manifest.header.uuid
    $version = ($manifest.header.version -join ', ')
    Write-Utf8NoBom (Join-Path $worldDir $p.WorldFile) "[`n  { `"pack_id`": `"$uuid`", `"version`": [$version] }`n]`n"
    Write-Host "Pack $($p.Dir) $($manifest.header.version -join '.') déployé"
}

# 4. Affichage des adresses IP locales à utiliser depuis la Switch
Write-Host ''
Write-Host 'Adresse(s) IP de ce PC (à taper sur la Switch, port 19132) :'
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
    ForEach-Object { Write-Host "  $($_.IPAddress)" }
Write-Host ''

if (-not $NoStart) {
    Write-Host 'Démarrage du serveur (tape "stop" pour l''arrêter)...'
    Push-Location $ServerDir
    try { & .\bedrock_server.exe } finally { Pop-Location }
}
