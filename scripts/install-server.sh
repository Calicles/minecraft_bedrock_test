#!/usr/bin/env bash
# Installe (si besoin) le Bedrock Dedicated Server dans ./server,
# y déploie mon_addon_BP / mon_addon_RP, puis lance le serveur.
# Relancer le script après chaque modification de l'addon pour le redéployer.
#
# Usage :
#   ./scripts/install-server.sh                      # télécharge la dernière version
#   ./scripts/install-server.sh /chemin/bedrock-server-x.y.z.zip
#   NO_START=1 ./scripts/install-server.sh           # déploie sans lancer
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$ROOT/server"
ZIP_PATH="${1:-}"

# 1. Téléchargement / extraction du serveur
if [[ ! -x "$SERVER_DIR/bedrock_server" ]]; then
  if [[ -z "$ZIP_PATH" ]]; then
    echo "Recherche de la dernière version du Bedrock Dedicated Server..."
    URL="$(curl -fsSL https://net-secondary.web.minecraft-services.net/api/v1.0/download/links \
      | python3 -c 'import json,sys; print(next(l["downloadUrl"] for l in json.load(sys.stdin)["result"]["links"] if l["downloadType"]=="serverBedrockLinux"))' \
      || true)"
    if [[ -z "$URL" ]]; then
      echo "Lien introuvable. Télécharge le zip Linux sur https://www.minecraft.net/download/server/bedrock" >&2
      echo "puis relance : $0 /chemin/du/zip" >&2
      exit 1
    fi
    ZIP_PATH="$(mktemp --suffix=.zip)"
    echo "Téléchargement de $URL"
    curl -fL -A "Mozilla/5.0" -o "$ZIP_PATH" "$URL"
  fi
  echo "Extraction dans $SERVER_DIR"
  mkdir -p "$SERVER_DIR"
  unzip -oq "$ZIP_PATH" -d "$SERVER_DIR"
  chmod +x "$SERVER_DIR/bedrock_server"
fi

# 2. Réglages de server.properties
PROPS="$SERVER_DIR/server.properties"
set_prop() {
  if grep -q "^$1=" "$PROPS"; then
    sed -i "s|^$1=.*|$1=$2|" "$PROPS"
  else
    echo "$1=$2" >> "$PROPS"
  fi
}
set_prop gamemode creative
set_prop allow-cheats true
set_prop texturepack-required true
set_prop content-log-file-enabled true
set_prop enable-lan-visibility true
set_prop allow-list false
LEVEL_NAME="$(grep '^level-name=' "$PROPS" | cut -d= -f2- | tr -d '\r')"

# 3. Copie des packs + activation sur le monde
WORLD_DIR="$SERVER_DIR/worlds/$LEVEL_NAME"
mkdir -p "$WORLD_DIR"
deploy_pack() { # $1 = dossier du pack, $2 = dossier cible, $3 = fichier world_*_packs.json
  rm -rf "$SERVER_DIR/$2/$1"
  cp -r "$ROOT/$1" "$SERVER_DIR/$2/$1"
  python3 - "$ROOT/$1/manifest.json" "$WORLD_DIR/$3" <<'EOF'
import json, sys
h = json.load(open(sys.argv[1]))["header"]
json.dump([{"pack_id": h["uuid"], "version": h["version"]}], open(sys.argv[2], "w"), indent=2)
print(f"Pack {h['name']} {'.'.join(map(str, h['version']))} déployé")
EOF
}
deploy_pack mon_addon_BP behavior_packs world_behavior_packs.json
deploy_pack mon_addon_RP resource_packs world_resource_packs.json

# 4. Adresses IP locales à utiliser depuis la Switch
echo
echo "Adresse(s) IP de cette machine (à taper sur la Switch, port 19132) :"
hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+\.' | sed 's/^/  /' || true
echo

if [[ -z "${NO_START:-}" ]]; then
  echo 'Démarrage du serveur (tape "stop" pour l'"'"'arrêter)...'
  cd "$SERVER_DIR"
  LD_LIBRARY_PATH=. exec ./bedrock_server
fi
