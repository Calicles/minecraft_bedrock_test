# Contexte du projet

Addon Minecraft Bedrock d'apprentissage (item `monaddon:rubis`), testé sur **Nintendo Switch**
via un Bedrock Dedicated Server (BDS) lancé sur le PC Windows de l'utilisateur.
L'utilisateur parle français : répondre en français.

## Configuration validée (octobre 2026)

- **PC** : Windows, IP locale `192.168.1.36`, projet cloné dans `C:\Users\Utilisateur\Desktop\projets\minecraft_bedrock_test`.
- **Switch** : Minecraft **1.26.52 (édition Switch 2)**, IP `192.168.1.79`, abonnement Nintendo Switch Online,
  compte Microsoft connecté dans Minecraft (obligatoire, sinon onglet Serveurs « hors ligne »).
- **Connexion Switch → serveur** : uniquement via **BedrockConnect** (DNS primaire `104.238.130.180`,
  secondaire `8.8.8.8`), en passant par un serveur partenaire compatible (Lifeboat, Mineville, The Hive,
  Galaxite, Enchanted), puis IP `192.168.1.36` port `19132`.
- **Ne marche pas** : la découverte « Parties LAN » (le « Réseau local » de la Switch = Switch ↔ Switch uniquement).
- **server.properties** imposés par `scripts/install-server.*` : `gamemode=creative`, `allow-cheats=true`,
  `texturepack-required=true`, `content-log-file-enabled=true`, `enable-lan-visibility=true`, `allow-list=false`.
- Commandes : `op <pseudo Xbox>` dans la console serveur, puis `/give @s monaddon:rubis` (chat = flèche droite).

## Pièges déjà rencontrés

- Erreur *Spyglass* « Vous n'êtes pas invité à jouer sur ce serveur » → liste blanche active (`allow-list`).
- Serveur partenaire qui s'ouvre normalement → serveur non compatible avec la redirection, ou cache DNS
  (éteindre complètement la Switch).
- `fix-firewall.ps1` exige l'admin → il se relance lui-même en administrateur.
- Les `.ps1` sont en UTF-8 **avec BOM** (Windows PowerShell 5.1) et CRLF (`.gitattributes`).

## Workflow de modification de l'addon

1. Modifier `mon_addon_BP/` ou `mon_addon_RP/` ; garder les UUID existants.
2. Incrémenter `version` dans le `manifest.json` modifié (sinon cache du resource pack sur la Switch).
3. `stop` dans la console, relancer `scripts\install-server.ps1`, se reconnecter.

## Après les tests

- PC : `scripts\restore-firewall.ps1` (règles pare-feu supprimées ; `-Public` pour repasser le réseau en Public).
- Switch : Paramètres DNS → Automatique.
