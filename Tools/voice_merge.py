#!/usr/bin/env python3
"""Fusionne un pack vocal supplémentaire dans Voice/Catalog.lua et Media/Voice/.

Le pack livré et le nouveau pack ne partagent pas la même convention de nommage,
et rien dans le nouveau ne doit remplacer une annonce existante : chaque fichier
reçoit une clé PREFIXEE, et les 185 entrées actuelles ne bougent pas.

Contrainte qui décide du reste : Core/Media.lua enregistre un chemin par entrée
du catalogue ET par pack. LSM:Fetch rend le chemin enregistré sans vérifier le
disque, donc une entrée dont le .ogg manque dans un pack ne se replie pas — elle
est simplement muette. Une entrée n'est donc créée que si le fichier existe dans
TOUS les packs livrés.
"""
import os, re, shutil, sys

REPO   = "repo"
PREFIX = "prep-"
CAT    = "Anticipation"
PACKS  = {"enUS": "voice/en/Voice/enUS", "frFR": "voice/fr/Voice/frFR"}

# Libellés affichés dans le menu des options.
#
# ILS SONT DÉRIVÉS DU NOM DE FICHIER, pas de l'écoute : ils décrivent ce que le
# nom annonce, et c'est au pack de dire si la voix correspond.
LABELS = {
    "absorb-shield": "Bouclier d'absorption",
    "action-click-gate": "Clique la porte",
    "action-drop-fire-back": "Pose le feu derrière",
    "action-drop-fire-front": "Pose le feu devant",
    "action-drop-fire-left": "Pose le feu à gauche",
    "action-drop-fire-right": "Pose le feu à droite",
    "action-guide-orb": "Guide l'orbe",
    "action-interrupt-1": "Interruption 1",
    "action-interrupt-2": "Interruption 2",
    "action-interrupt-3": "Interruption 3",
    "action-prepare-middle": "Prépare-toi au centre",
    "action-prepare-orb": "Prépare l'orbe",
    "action-swap": "Échange",
    "action-wait-gate": "Attends à la porte",
    "adds": "Adds",
    "aimed": "Tir visé",
    "aoe": "AoE",
    "aoe-2": "AoE (variante)",
    "avoid-middle": "Évite le centre",
    "away": "Éloigne-toi",
    "back": "Recule",
    "beam": "Rayon",
    "big-add": "Gros add",
    "bleed": "Saignement",
    "block-line": "Bloque la ligne",
    "block-soul": "Bloque l'âme",
    "break-link": "Casse le lien",
    "break-shield": "Casse le bouclier",
    "buff": "Buff",
    "cc": "CC",
    "cc-2": "CC (variante)",
    "charge": "Charge",
    "circle": "Cercle",
    "clone": "Clone",
    "close": "Rapproche-toi",
    "count-1": "Décompte 1",
    "count-2": "Décompte 2",
    "count-3": "Décompte 3",
    "count-4": "Décompte 4",
    "count-5": "Décompte 5",
    "countdown": "Décompte",
    "curse": "Malédiction",
    "curse-stacks": "Cumuls de malédiction",
    "dispel": "Dissipe",
    "dispel-magic": "Dissipe la magie",
    "dispel-tank": "Dissipe le tank",
    "do-mechanics": "Fais la mécanique",
    "dodge": "Esquive",
    "dodge-2": "Esquive (variante)",
    "dodge-3": "Esquive (variante 3)",
    "dot": "DoT",
    "drop": "Pose",
    "drop-2": "Pose (variante)",
    "drop-soul": "Pose l'âme",
    "empowered-add": "Add renforcé",
    "enrage": "Enrage",
    "enrage-stacks": "Cumuls d'enrage",
    "five-stars": "Cinq étoiles",
    "fixate": "Fixation",
    "food-delivery": "Livraison",
    "freedom": "Liberté",
    "frontal": "Frontal",
    "frontal-spike": "Pointe frontale",
    "green-barrel": "Baril vert",
    "group-bleed": "Saignement de groupe",
    "heal-tank": "Soigne le tank",
    "housekeeping": "Ménage",
    "in": "Rentre",
    "in-2": "Rentre (variante)",
    "interrupt": "Interromps",
    "kick-customer": "Vire le client",
    "knock": "Projection",
    "leap": "Bond",
    "los": "Ligne de vue",
    "lucio": "Lúcio",
    "magic": "Magie",
    "marked": "Marqué",
    "marked-2": "Marqué (variante)",
    "move": "Bouge",
    "move-out": "Sors",
    "move-to-boss": "Va sur le boss",
    "mushrooms-growing": "Champignons qui poussent",
    "orb": "Orbe",
    "orb-2": "Orbe (variante)",
    "persistent-aoe": "AoE persistante",
    "phase-change": "Changement de phase",
    "poison": "Poison",
    "rescue": "Sauvetage",
    "safe": "C'est sûr",
    "shield": "Bouclier",
    "shield-removed": "Bouclier retiré",
    "snare": "Entrave",
    "soak": "Absorbe",
    "soak-2": "Absorbe (variante)",
    "soak-orb": "Absorbe l'orbe",
    "soul": "Âme",
    "spellsteal": "Vol de sort",
    "spread": "Écartez-vous",
    "stack": "Regroupement",
    "stop-casting": "Arrête d'incanter",
    "switch": "Change de cible",
    "tank-debuff": "Debuff de tank",
    "tank-vulnerability": "Vulnérabilité du tank",
    "tankbuster": "Tank buster",
    "totem": "Totem",
    "vulnerability": "Vulnérabilité",
    "vulnerability-ended": "Vulnérabilité terminée",
    "vulnerability-stacks": "Cumuls de vulnérabilité",
    "wind": "Vent",
}

norm = lambda s: s.replace("_", "-")


def main():
    # 1. Inventaire des deux packs, par nom normalisé.
    have = {}
    for lang, path in PACKS.items():
        have[lang] = {norm(f[:-4]): f for f in os.listdir(path) if f.endswith(".ogg")}

    common = set.intersection(*(set(v) for v in have.values()))
    partial = sorted(set().union(*(set(v) for v in have.values())) - common)

    # 2. Clés déjà prises : on refuse toute collision plutôt que d'écraser.
    cat_src = open(os.path.join(REPO, "Voice/Catalog.lua"), encoding="utf-8").read()
    existing = set(re.findall(r'\["([^"]+)"\] = \{', cat_src))
    files_used = set(re.findall(r'file = "([^"]+)"', cat_src))

    entries, clashes, unlabelled = [], [], []
    for name in sorted(common):
        key, fname = PREFIX + name, PREFIX + name + ".ogg"
        if key in existing or fname in files_used:
            clashes.append(key)
            continue
        label = LABELS.get(name)
        if not label:
            unlabelled.append(name)
            continue
        entries.append((key, label, fname, name))

    if clashes:
        sys.exit("collision de clé : " + ", ".join(clashes))
    if unlabelled:
        sys.exit("libellé manquant : " + ", ".join(unlabelled))

    # 3. Copie des fichiers, sous le nom préfixé, dans chaque pack.
    copied = 0
    for lang, path in PACKS.items():
        dest = os.path.join(REPO, "Media/Voice", lang)
        for key, label, fname, name in entries:
            shutil.copyfile(os.path.join(path, have[lang][name]),
                            os.path.join(dest, fname))
            copied += 1

    # 4. Insertion dans le catalogue, en bloc marqué, avant l'accolade finale.
    block = [
        "",
        "    -- ----------------------------------------------------------------",
        "    -- Pack « Anticipation » — annonces de préparation aux sorts à venir.",
        "    --",
        "    -- Ajouté sans rien remplacer : ces annonces portent le préfixe " + PREFIX,
        "    -- et cohabitent avec les entrées d'origine, qui gardent leurs voix.",
        "    -- Les libellés viennent du nom de fichier, pas d'une écoute.",
        "    -- ----------------------------------------------------------------",
    ]
    for key, label, fname, _ in entries:
        block.append('    ["%s"] = { fr = "%s", file = "%s", cat = "%s" },'
                     % (key, label.replace('"', '\\"'), fname, CAT))

    idx = cat_src.rstrip().rfind("\n}")
    if idx < 0:
        sys.exit("fin de table introuvable dans Voice/Catalog.lua")
    out = cat_src[:idx] + "\n" + "\n".join(block) + cat_src[idx:]
    open(os.path.join(REPO, "Voice/Catalog.lua"), "w", encoding="utf-8").write(out)

    print("entrées ajoutées : %d" % len(entries))
    print("fichiers copiés  : %d (%d par pack)" % (copied, len(entries)))
    if partial:
        print("ÉCARTÉS (absents d'au moins un pack, ils seraient muets) : %s"
              % ", ".join(partial))


if __name__ == "__main__":
    main()
