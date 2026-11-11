# Changelog — Wild Overdrive

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Le versionning suit strictement la convention unique `v1.x.y`.

## [v1.0.1] - 2026-11-11

### Corrigé
- **Pipeline CI/CD & Analyse Statique Multi-Version Flutter (`.github/workflows/build-apk.yml` & `analysis_options.yaml`)** :
  - Épinglage explicite de Flutter `3.47.9` dans GitHub Actions et compatibilité ascendante de l'analyseur avec Flutter `3.50.0+` pour la génération de l'APK Android Release (`wild-overdrive-v1.0.1.apk`).

## [v1.0.0] - 2026-11-11

### Ajouté
- **Moteur d'Arcade Roguelite & Bullet-Heaven 60 FPS (`lib/engine/wild_game_engine.dart`)** :
  - Simulation temps réel et déterministe avec physique 2D vectorielle, ciblage intelligent, gestion des collisions, particules, ondes de choc (`ShockwaveRing`) et éclairs en chaîne (`LightningArc`).
  - **Système Central "GO WILD!" (`Furie Sauvage`)** : jauge d'Overdrive se chargeant par récolte de bio-cristaux et éliminations, déclenchant une cadence de tir `×2.6`, 4 lames orbitales plasma, l'aimantation intégrale de l'arène, une onde thermonucléaire et le multiplicateur de combo sauvage.
- **4 Chasseurs Apex Jouables (`lib/models/wild_models.dart`)** :
  - `REX-9 SOLAR FANG` (Canons plasma jumelés & *Supernova Solaire*).
  - `VIPER-X VOID PHANTOM` (Railgun perforant & *Distorsion Temporelle*).
  - `KRAKEN-7 STORM ARCHITECT` (Arcs Tesla en chaîne & *Tempête Ionique Oméga*).
  - `VALKYRIE-Ω SINGULARITY QUEEN` (Lames de graviton & *Trou Noir Sauvage*).
- **4 Dimensions / Biomes Cosmiques Dynamiques** :
  - *Jungle Bioluminescente*, *Forge Magmatique*, *Abysse Cyber-Quantique* et *Singularité Sauvage Ω*.
- **18 Mutations Sauvages Synergiques (3 Paliers de Rareté : Tactique, Épique, Mythique Sauvage)** :
  - Tirage évolutif de 3 cartes en direct avec relance (`Reroll`) et accès complet via le Codex interactif.
- **6 Archétypes d'Essaims & 3 Boss Colossaux (`Léviathan Néon X-9`, `Hydre Solaire Hélios`, `Architecte Sauvage Ω`)** :
  - Patterns de tir radiaux, boucliers énergétiques, division cellulaire (*Splitter*) et barre de vie de Boss dédiée.
- **Rendu Vectoriel Haute Précision (`CustomPainter` — `lib/painters/wild_arena_painter.dart`)** :
  - Nébuleuses procédurales, grille cybernétique réactive, silhouettes multi-couches des vaisseaux et boss, arcs électriques et textes flottants de dégâts critiques.
- **Pipeline CI/CD GitHub Actions (`.github/workflows/build-apk.yml`)** :
  - Analyse statique stricte (`flutter analyze`), tests unitaires/widgets Portrait `1080×2400` (`flutter test`) et compilation/publication automatique de l'APK Android Release (`wild-overdrive-v1.0.0.apk`).
