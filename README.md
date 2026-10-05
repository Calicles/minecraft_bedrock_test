# minecraft_bedrock_test

Addon Minecraft Bedrock d'exemple (un item **Rubis**), testable sur **Nintendo Switch**
via un Bedrock Dedicated Server (BDS) lancé sur un PC.

## Contenu

| Dossier | Rôle |
|---|---|
| `mon_addon_BP/` | Behavior Pack : l'item `monaddon:rubis` + une recette (9 diamants → 1 rubis) |
| `mon_addon_RP/` | Resource Pack : texture, icône, noms FR/EN |
| `scripts/install-server.ps1` | Windows : installe le BDS, déploie l'addon, lance le serveur |
| `scripts/install-server.sh` | Linux : idem |

## 1. Lancer le serveur sur le PC

Le PC n'a **pas besoin** d'avoir Minecraft installé.

**Windows** (PowerShell, à la racine du dépôt) :
```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-server.ps1
```

**Linux** (Ubuntu/Debian x86_64) :
```bash
./scripts/install-server.sh
```

Le script :
1. télécharge la dernière version du BDS dans `server/` (premier lancement seulement) ;
2. règle `server.properties` : créatif, cheats activés, resource pack obligatoire ;
3. copie les deux packs et les active sur le monde (`world_behavior_packs.json` / `world_resource_packs.json`) ;
4. affiche l'IP locale du PC, puis démarre le serveur.

Si le téléchargement automatique échoue, télécharge le zip sur
<https://www.minecraft.net/download/server/bedrock> et passe son chemin au script
(`-ZipPath C:\...\bedrock-server.zip` sous Windows, `./scripts/install-server.sh /chemin/zip` sous Linux).

Au premier lancement, Windows demande d'autoriser `bedrock_server.exe` dans le pare-feu :
accepte pour les **réseaux privés** (port UDP 19132).

## 2. Se connecter depuis la Switch

La Switch ne permet pas d'ajouter un serveur par IP. On passe par **BedrockConnect** :

1. Switch → Paramètres → Internet → ta connexion → Modifier les paramètres →
   **Paramètres DNS : Manuel** → DNS primaire = l'IP indiquée dans le README de
   <https://github.com/Pugmatt/BedrockConnect>, DNS secondaire = `8.8.8.8`.
2. Lance Minecraft → Jouer → onglet **Serveurs** → clique sur n'importe quel serveur partenaire.
3. Le menu BedrockConnect s'ouvre → **Connect to a Server** → IP affichée par le script, port `19132`.

La Switch et le PC doivent être sur le même réseau. Un abonnement Nintendo Switch Online est requis.

## 3. Tester l'addon

En jeu : `/give @s monaddon:rubis`, ou crafte 9 diamants sur un établi.
Les erreurs de l'addon (JSON invalide, identifiant inconnu…) s'affichent dans la console du serveur.

## 4. Après une modification

1. Augmente `version` dans le(s) `manifest.json` modifié(s) (ex. `[1, 0, 1]`),
   sinon la Switch peut garder l'ancien resource pack en cache.
2. Dans la console du serveur, tape `stop`.
3. Relance le script : il redéploie les packs et redémarre le serveur.
4. Reconnecte-toi depuis la Switch.
