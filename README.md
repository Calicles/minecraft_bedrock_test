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
| `scripts/fix-firewall.ps1` | Windows : profil réseau Privé + règles pare-feu (diagnostic) |
| `scripts/restore-firewall.ps1` | Windows : supprime ces règles après les tests (`-Public` pour repasser le réseau en Public) |

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

## 2. Se connecter depuis la Switch (via BedrockConnect)

Prérequis : **Nintendo Switch Online** + **compte Microsoft connecté** dans Minecraft
(bouton « Se connecter avec un compte Microsoft » du menu principal, code à saisir sur <https://aka.ms/remoteconnect>).
Sans compte Microsoft, l'onglet Serveurs affiche « Vous êtes hors ligne ».

> La découverte « Parties LAN » ne fonctionne pas sur Switch : le « Réseau local » de la Switch
> ne sert qu'à jouer avec d'autres Switch à proximité.

1. Switch → Paramètres de la console → Internet → Paramètres Internet → ton Wi-Fi → Modifier les paramètres →
   **Paramètres DNS : Manuel** → DNS primaire `104.238.130.180`, DNS secondaire `8.8.8.8`
   (adresse à revérifier sur <https://github.com/Pugmatt/BedrockConnect>).
2. **Éteins complètement** la Switch puis rallume-la (vide le cache DNS).
3. Minecraft → Jouer → **Serveurs** → choisis un serveur compatible : **Lifeboat, Mineville, The Hive, Galaxite ou Enchanted**
   (les autres, comme CubeCraft, ne redirigent pas).
4. Menu BedrockConnect → **Connect to a Server** → IP du PC (affichée par le script), port `19132`, coche « Add to server list ».

Pour revenir à la normale : Paramètres DNS → **Automatique**.

## 3. Tester l'addon

1. Dans la console du serveur : `op TonPseudoXbox` (droits pour les commandes).
2. Sur la Switch, ouvre le chat (**flèche droite** de la croix) : `/give @s monaddon:rubis`.
   Ou inventaire créatif (X) → recherche « Rubis ». Ou établi : 9 diamants → 1 rubis.

Les erreurs de l'addon s'affichent dans la console du serveur.

## Dépannage

| Symptôme | Cause / solution |
|---|---|
| « Vous êtes hors ligne » dans Serveurs | Compte Microsoft non connecté dans Minecraft |
| Le serveur partenaire s'ouvre normalement | Serveur non compatible avec la redirection, ou DNS en cache → éteindre la Switch |
| « Vous n'êtes pas invité à jouer sur ce serveur » (code *Spyglass*) | Liste blanche active : `allow-list=false` (le script le règle) ou `allowlist add TonPseudoXbox` |
| Connexion refusée sans message clair | Version du serveur différente de celle de la Switch (bas droite du menu principal) |
| Le serveur n'est pas joignable | `scripts\fix-firewall.ps1` (profil réseau Privé + règles pare-feu, se relance en admin) |
| Rubis violet/noir | Resource pack non téléchargé : se reconnecter, augmenter la `version` du manifest |

## 4. Après une modification

1. Augmente `version` dans le(s) `manifest.json` modifié(s) (ex. `[1, 0, 1]`),
   sinon la Switch peut garder l'ancien resource pack en cache.
2. Dans la console du serveur, tape `stop`.
3. Relance le script : il redéploie les packs et redémarre le serveur.
4. Reconnecte-toi depuis la Switch.

## 5. Après les tests : tout remettre comme avant

- **PC** : `powershell -ExecutionPolicy Bypass -File scripts\restore-firewall.ps1` (supprime les règles pare-feu).
- **Switch** : Paramètres DNS → **Automatique** (sinon toutes les requêtes DNS passent par BedrockConnect
  et les serveurs partenaires restent redirigés).
