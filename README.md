# TomoBoss

# ![TomoBoss](https://img.shields.io/badge/TomoBoss-v2.3.5-0cd29f?style=for-the-badge) ![WoW](https://img.shields.io/badge/WoW-Midnight-blue?style=for-the-badge) ![Interface](https://img.shields.io/badge/Interface-120007-orange?style=for-the-badge)

Minuteurs de boss + voix française pour World of Warcraft (Midnight, interface 12.0).
Interface sombre (dark black) et menthe.

**Pack audio français** : VoixFrancaise02 (Melune) — 185 annonces, embarquées.

---

## Commandes

| Commande | Effet |
|---|---|
| `/tmb` | Ouvre / ferme les options |
| `/tmb pull [n]` | Décompte de pull (défaut 10 s) — groupe ou solo |
| `/tmb pull stop` | Annule le décompte |
| `/tmb test` | Lance un aperçu des minuteurs (boss de démonstration) |
| `/tmb test stop` | Arrête l'aperçu |
| `/tmb unlock` / `/tmb lock` | Déverrouille / verrouille les éléments à l'écran |
| `/tmb reset` | Réinitialise les positions |
| `/tmb voix <id>` | Teste une annonce vocale (ex. `/tmb voix interrupt-now`) |
| `/pull [n]` | Alias, si aucun autre addon de pull n'est chargé |

---

## Ce qui est inclus

- **Moteur de timeline** : prédit les capacités de boss (`firstSeenSec` + `cdSeriesSec`) et se
  resynchronise sur les incantations réelles quand le `spellID` est lisible. En Midnight, les
  `spellID` de `UNIT_SPELLCAST_*` sont masqués (secretvalue) ; l'addon bascule alors sur la
  prédiction pure — d'où l'importance des données de timeline.
- **Barres de minuteur** empilées, triées par temps restant, colorées par sévérité
  (bleu = tank, menthe = normal, corail = danger).
- **Voix française** jouée pour chaque capacité, via LibSharedMedia.
- **Grand compte à rebours** central au pull, avec voix 5-4-3-2-1.
- **Alerte texte centrale** pour les mécaniques dangereuses (sévérité 2).
- **Mode édition** : `/tmb unlock` pour déplacer chaque élément, positions sauvegardées.
- **Options thémées** : barres, voix, compte à rebours, échelle globale.

**Rencontres fournies** : les 8 donjons de la saison 12.0 S1, soit **29 boss / 122 capacités** :

| Donjon | Boss |
|---|---|
| Fosse de Saron | Garfrost · Ick & Krick · Tyrannus |
| Cime-du-Ciel | Ranjit · Araknath · Rukhran · Grande sage Viryx |
| Siège du Triumvirat | Zuraal · Saprish · Vice-roi Nezhar · Lura |
| Académie d'Algeth'ar | Vexamus · Ancien surdimensionné · Crawth · Écho de Doragosa |
| Flèche des Coursevent | Emberdawn · Duo décrépit · Commandant Kroluk · Cœur agité |
| Terrasse des Magistères | Construct · Selanar · Gemellus · Degentrius |
| Cavernes de Maisara | Murojin & Nekraxx · Vordaza · Raktul |
| Point de Nexus : Xenas | Kasreth · Nysarra · Lothraxion |

> Les noms de capacités affichés sur les barres sont résolus **en direct depuis le client**
> via le `spellID` : sur un client français ils apparaissent en français, sans traduction manuelle.
> Repli automatique sur le libellé vocal français si le nom du sort n'est pas disponible.
>
> Les raids et la saison 2 ne sont pas inclus.

---

## Ajouter un boss

Créez/éditez un fichier chargé après `Engine/Timeline.lua` (par ex. dans `Engine/EncounterData.lua`) :

```lua
local NS = select(2, ...)
NS.Engine:RegisterEncounter(ENCOUNTER_ID, {
    name    = "Nom du boss",
    dungeon = "Nom du donjon",
    events = {
        { name = "Nom de la capacité",
          role = "tank",            -- tank | heal | dps | mechanic | other
          voice = "interrupt-now",  -- id du catalogue vocal (Voice/Catalog.lua)
          spellID = 123456,         -- pour la resynchronisation sur l'incantation
          castType = "begincast",   -- begincast | cast | channel
          castDuration = 4.0,
          firstSeenSec = 10,        -- première apparition (s après le pull)
          cdSeriesSec = { 30 },     -- intervalle(s) de récurrence, en boucle
          severity = 1,             -- 0 info/tank, 1 normal, 2 danger (flash)
          preAlertSec = 3,          -- (optionnel) avance de l'annonce
        },
    },
})
```

- `ENCOUNTER_ID` = l'id renvoyé par l'événement `ENCOUNTER_START` (id de rencontre du journal).

### Liste des id vocaux
Toutes les annonces disponibles sont dans `Voice/Catalog.lua` (champ `fr` = libellé,
clé = id à utiliser dans `voice`). Testez-en une avec `/tmb voix <id>`.

---

## Crédits
- Moteur, interface, intégration : TomoAniki.
- Voix française : Voix Francaise.
- Bibliothèques : LibStub, CallbackHandler-1.0, LibSharedMedia-3.0.
