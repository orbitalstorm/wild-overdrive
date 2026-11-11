import 'package:flutter/material.dart';

enum WildClassId {
  solarFang,
  voidPhantom,
  stormKraken,
  singularityValkyrie,
}

enum WeaponPattern {
  twinPlasma,
  piercingRailgun,
  teslaChain,
  gravitonBlades,
}

class WildHunterSpec {
  const WildHunterSpec({
    required this.id,
    required this.codeName,
    required this.title,
    required this.role,
    required this.description,
    required this.ultimateName,
    required this.ultimateDescription,
    required this.primaryColor,
    required this.secondaryColor,
    required this.maxHp,
    required this.maxShield,
    required this.speed,
    required this.fireRatePerSec,
    required this.baseDamage,
    required this.weaponPattern,
    required this.icon,
  });

  final WildClassId id;
  final String codeName;
  final String title;
  final String role;
  final String description;
  final String ultimateName;
  final String ultimateDescription;
  final Color primaryColor;
  final Color secondaryColor;
  final double maxHp;
  final double maxShield;
  final double speed;
  final double fireRatePerSec;
  final double baseDamage;
  final WeaponPattern weaponPattern;
  final IconData icon;

  static const List<WildHunterSpec> catalog = <WildHunterSpec>[
    WildHunterSpec(
      id: WildClassId.solarFang,
      codeName: 'REX-9',
      title: 'SOLAR FANG',
      role: 'Berserker Solaire & Artillerie Lourde',
      description:
          'Chasseur d\'assaut doté de canons plasma jumelés à haute cadence et d\'un blindage réactif.',
      ultimateName: 'SUPERNOVA SOLAIRE',
      ultimateDescription:
          'Déclenche une onde thermonucléaire radiale et triple la cadence des canons plasma.',
      primaryColor: Color(0xFFFF6B00),
      secondaryColor: Color(0xFFFFD600),
      maxHp: 220,
      maxShield: 80,
      speed: 255,
      fireRatePerSec: 6.5,
      baseDamage: 28,
      weaponPattern: WeaponPattern.twinPlasma,
      icon: Icons.local_fire_department_rounded,
    ),
    WildHunterSpec(
      id: WildClassId.voidPhantom,
      codeName: 'VIPER-X',
      title: 'VOID PHANTOM',
      role: 'Spectre Quantique & Railgun Perforant',
      description:
          'Intercepteur furtif ultra-rapide tirant des faisceaux railgun qui transpercent plusieurs cibles.',
      ultimateName: 'DISTORSION TEMPORELLE',
      ultimateDescription:
          'Ralentit tous les ennemis de l\'arène de 60 % et garantit des tirs critiques perforants.',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF7C4DFF),
      maxHp: 170,
      maxShield: 110,
      speed: 310,
      fireRatePerSec: 4.8,
      baseDamage: 44,
      weaponPattern: WeaponPattern.piercingRailgun,
      icon: Icons.bolt_rounded,
    ),
    WildHunterSpec(
      id: WildClassId.stormKraken,
      codeName: 'KRAKEN-7',
      title: 'STORM ARCHITECT',
      role: 'Architecte d\'Orage & Arcs Tesla',
      description:
          'Vaisseau expérimental projetant des arcs électriques en chaîne et des bobines ioniques.',
      ultimateName: 'TEMPÊTE IONIQUE OMÉGA',
      ultimateDescription:
          'Foudroie simultanément jusqu\'à 8 ennemis avec des éclairs en chaîne survoltés.',
      primaryColor: Color(0xFF00FF9D),
      secondaryColor: Color(0xFF00B8D4),
      maxHp: 200,
      maxShield: 120,
      speed: 245,
      fireRatePerSec: 5.6,
      baseDamage: 32,
      weaponPattern: WeaponPattern.teslaChain,
      icon: Icons.electric_bolt_rounded,
    ),
    WildHunterSpec(
      id: WildClassId.singularityValkyrie,
      codeName: 'VALKYRIE-Ω',
      title: 'SINGULARITY QUEEN',
      role: 'Dominatrice Gravitationnelle & Lames Vortex',
      description:
          'Émet des disques de graviton tranchants et manipule la gravité pour broyer les essaims.',
      ultimateName: 'TROU NOIR SAUVAGE',
      ultimateDescription:
          'Génère une singularité qui aspire les essaims ennemis et fait imploser leurs noyaux.',
      primaryColor: Color(0xFFFF007F),
      secondaryColor: Color(0xFFE040FB),
      maxHp: 210,
      maxShield: 100,
      speed: 270,
      fireRatePerSec: 5.8,
      baseDamage: 35,
      weaponPattern: WeaponPattern.gravitonBlades,
      icon: Icons.cyclone_rounded,
    ),
  ];

  static WildHunterSpec byId(WildClassId id) {
    for (final WildHunterSpec spec in catalog) {
      if (spec.id == id) {
        return spec;
      }
    }
    return catalog.first;
  }
}

enum WildBiomeId {
  neonJungle,
  solarForge,
  quantumAbyss,
  omegaSingularity,
}

class WildBiomeSpec {
  const WildBiomeSpec({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.modifierLabel,
    required this.bgTop,
    required this.bgBottom,
    required this.gridColor,
    required this.nebulaColor,
    required this.accentColor,
  });

  final WildBiomeId id;
  final String name;
  final String subtitle;
  final String modifierLabel;
  final Color bgTop;
  final Color bgBottom;
  final Color gridColor;
  final Color nebulaColor;
  final Color accentColor;

  static const List<WildBiomeSpec> catalog = <WildBiomeSpec>[
    WildBiomeSpec(
      id: WildBiomeId.neonJungle,
      name: 'JUNGLE BIOLUMINESCENTE',
      subtitle: 'Secteur Émeraude X-01',
      modifierLabel: '+25 % Bio-Cristaux • Essaims Rapides',
      bgTop: Color(0xFF041318),
      bgBottom: Color(0xFF071F24),
      gridColor: Color(0xFF00E676),
      nebulaColor: Color(0xFF00BFA5),
      accentColor: Color(0xFF00FF9D),
    ),
    WildBiomeSpec(
      id: WildBiomeId.solarForge,
      name: 'FORGE MAGMATIQUE',
      subtitle: 'Cœur Solaire Hélios-9',
      modifierLabel: '+20 % Dégâts Critiques • Éruptions Plasma',
      bgTop: Color(0xFF1A0805),
      bgBottom: Color(0xFF280D07),
      gridColor: Color(0xFFFF6D00),
      nebulaColor: Color(0xFFFF3D00),
      accentColor: Color(0xFFFFAB00),
    ),
    WildBiomeSpec(
      id: WildBiomeId.quantumAbyss,
      name: 'ABYSSE CYBER-QUANTIQUE',
      subtitle: 'Nébuleuse Tachyon V-7',
      modifierLabel: '+30 % Vitesse de Charge WILD • Spectres Phasiques',
      bgTop: Color(0xFF07081C),
      bgBottom: Color(0xFF100B2B),
      gridColor: Color(0xFF00E5FF),
      nebulaColor: Color(0xFF651FFF),
      accentColor: Color(0xFF18FFFF),
    ),
    WildBiomeSpec(
      id: WildBiomeId.omegaSingularity,
      name: 'SINGULARITÉ SAUVAGE Ω',
      subtitle: 'Horizon des Événements',
      modifierLabel: 'Score ×2 • Anomalies Gravitationnelles',
      bgTop: Color(0xFF16041A),
      bgBottom: Color(0xFF240729),
      gridColor: Color(0xFFFF007F),
      nebulaColor: Color(0xFFD500F9),
      accentColor: Color(0xFFFF4081),
    ),
  ];

  static WildBiomeSpec byId(WildBiomeId id) {
    for (final WildBiomeSpec spec in catalog) {
      if (spec.id == id) {
        return spec;
      }
    }
    return catalog.first;
  }
}

enum MutationRarity {
  common,
  epic,
  wildMythic,
}

enum MutationId {
  orbitalBlades,
  chainLightning,
  twinDroneWingmen,
  homingSwarm,
  vampiricFury,
  criticalOvercharge,
  voraciousMagnet,
  novaShield,
  hyperThrusters,
  plasmaRicochet,
  wildCatalyst,
  singularityCore,
  cryoStasis,
  titanHull,
  solarAfterburner,
  omniBarrage,
  crystalAlchemy,
  omegaExecution,
}

class MutationSpec {
  const MutationSpec({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.rarity,
    required this.color,
    required this.icon,
    this.maxStacks = 5,
  });

  final MutationId id;
  final String name;
  final String category;
  final String description;
  final MutationRarity rarity;
  final Color color;
  final IconData icon;
  final int maxStacks;

  String get rarityLabel {
    switch (rarity) {
      case MutationRarity.common:
        return 'SYNERGIE TACTIQUE';
      case MutationRarity.epic:
        return 'MUTATION ÉPIQUE';
      case MutationRarity.wildMythic:
        return 'MYTHIQUE SAUVAGE';
    }
  }

  static const List<MutationSpec> catalog = <MutationSpec>[
    MutationSpec(
      id: MutationId.orbitalBlades,
      name: 'Lames Orbitales Plasma',
      category: 'Armement Orbital',
      description:
          'Déploie des scies énergétiques en rotation autour du vaisseau qui découpent les ennemis au contact.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFFFF007F),
      icon: Icons.motion_photos_on_rounded,
    ),
    MutationSpec(
      id: MutationId.chainLightning,
      name: 'Arcs Tesla en Chaîne',
      category: 'Surcharge Électrique',
      description:
          'Chaque impact projette un éclair haute tension qui foudroie jusqu\'à 3 cibles proches.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFF00E5FF),
      icon: Icons.electric_bolt_rounded,
    ),
    MutationSpec(
      id: MutationId.twinDroneWingmen,
      name: 'Clones Fantômes',
      category: 'Escadrille Autonome',
      description:
          'Invoque deux ailiers holographiques qui copient vos tirs et couvrent vos flancs.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFF00FF9D),
      icon: Icons.smart_toy_rounded,
    ),
    MutationSpec(
      id: MutationId.homingSwarm,
      name: 'Essaim de Micro-Missiles',
      category: 'Artillerie Guidée',
      description:
          'Lance automatiquement une salve de missiles autoguidés vers les menaces prioritaires.',
      rarity: MutationRarity.epic,
      color: Color(0xFFFF9100),
      icon: Icons.rocket_launch_rounded,
    ),
    MutationSpec(
      id: MutationId.vampiricFury,
      name: 'Vampirisme Sauvage',
      category: 'Bio-Régénération',
      description:
          'Les éliminations régénèrent la coque (+4 PV, doublé pendant le mode GO WILD!).',
      rarity: MutationRarity.epic,
      color: Color(0xFFFF1744),
      icon: Icons.favorite_rounded,
    ),
    MutationSpec(
      id: MutationId.criticalOvercharge,
      name: 'Surcharge Critique ×2.5',
      category: 'Amplificateur',
      description:
          '+20 % de chances de coup critique explosif infligeant 250 % de dégâts.',
      rarity: MutationRarity.epic,
      color: Color(0xFFFFEA00),
      icon: Icons.flare_rounded,
    ),
    MutationSpec(
      id: MutationId.voraciousMagnet,
      name: 'Aimant Bio-Vorace',
      category: 'Récolte Quantique',
      description:
          '+75 % de rayon d\'attraction des bio-cristaux et +25 % de gain d\'expérience.',
      rarity: MutationRarity.common,
      color: Color(0xFF69F0AE),
      icon: Icons.attractions_rounded,
    ),
    MutationSpec(
      id: MutationId.novaShield,
      name: 'Bouclier à Impulsion Nova',
      category: 'Défense Active',
      description:
          'Émet périodiquement une onde de choc qui vaporise les projectiles ennemis et recharge le bouclier.',
      rarity: MutationRarity.epic,
      color: Color(0xFF40C4FF),
      icon: Icons.shield_rounded,
    ),
    MutationSpec(
      id: MutationId.hyperThrusters,
      name: 'Propulseurs Hyper-Flux',
      category: 'Mobilité',
      description:
          '+22 % de vitesse de déplacement et réduction de 25 % du temps de recharge du Dash.',
      rarity: MutationRarity.common,
      color: Color(0xFF18FFFF),
      icon: Icons.speed_rounded,
    ),
    MutationSpec(
      id: MutationId.plasmaRicochet,
      name: 'Ricochet Photonique',
      category: 'Balistique',
      description:
          'Les projectiles traversent +1 cible supplémentaire et gagnent +18 % de vélocité.',
      rarity: MutationRarity.common,
      color: Color(0xFFB388FF),
      icon: Icons.call_split_rounded,
    ),
    MutationSpec(
      id: MutationId.wildCatalyst,
      name: 'Catalyseur GO WILD!',
      category: 'Furie Sauvage',
      description:
          'La jauge de Furie Sauvage se remplit 40 % plus vite et prolonge l\'Overdrive de +3 s.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFFFFD600),
      icon: Icons.whatshot_rounded,
    ),
    MutationSpec(
      id: MutationId.singularityCore,
      name: 'Cœur Gravitationnel',
      category: 'Anomalie',
      description:
          'Chaque ennemi détruit crée une implosion qui attire les cibles voisines.',
      rarity: MutationRarity.epic,
      color: Color(0xFFE040FB),
      icon: Icons.blur_circular_rounded,
    ),
    MutationSpec(
      id: MutationId.cryoStasis,
      name: 'Gel Stase Quantique',
      category: 'Contrôle',
      description:
          'Vos impacts ralentissent les ennemis de 30 % et fragilisent leur blindage (+15 % dégâts).',
      rarity: MutationRarity.common,
      color: Color(0xFF80D8FF),
      icon: Icons.ac_unit_rounded,
    ),
    MutationSpec(
      id: MutationId.titanHull,
      name: 'Blindage Bio-Titane',
      category: 'Survie',
      description:
          '+50 PV Maximum, +30 Bouclier et réparation automatique continue en combat.',
      rarity: MutationRarity.common,
      color: Color(0xFFA7FFEB),
      icon: Icons.health_and_safety_rounded,
    ),
    MutationSpec(
      id: MutationId.solarAfterburner,
      name: 'Sillage Solaire Ardent',
      category: 'Mobilité Offensive',
      description:
          'Le Dash Phasique déclenche une déflagration thermique qui carbonise les poursuivants.',
      rarity: MutationRarity.common,
      color: Color(0xFFFF6E40),
      icon: Icons.air_rounded,
    ),
    MutationSpec(
      id: MutationId.omniBarrage,
      name: 'Barrage Stellaire 360°',
      category: 'Saturation',
      description:
          'Toutes les 5 salves, libère une couronne de 10 projectiles plasma dans toutes les directions.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFFFF4081),
      icon: Icons.all_out_rounded,
    ),
    MutationSpec(
      id: MutationId.crystalAlchemy,
      name: 'Alchimie Cristalline',
      category: 'Économie & Chaos',
      description:
          'Ramasser un bio-cristal déclenche un tir ionique automatique vers l\'ennemi le plus proche.',
      rarity: MutationRarity.common,
      color: Color(0xFF64FFDA),
      icon: Icons.auto_awesome_rounded,
    ),
    MutationSpec(
      id: MutationId.omegaExecution,
      name: 'Exécution Oméga',
      category: 'Fatalité',
      description:
          'Désintègre instantanément tout ennemi standard sous 20 % de PV et +35 % dégâts contre les Boss.',
      rarity: MutationRarity.wildMythic,
      color: Color(0xFFFF5252),
      icon: Icons.gavel_rounded,
    ),
  ];

  static MutationSpec byId(MutationId id) {
    for (final MutationSpec spec in catalog) {
      if (spec.id == id) {
        return spec;
      }
    }
    return catalog.first;
  }
}

enum EnemyArchetype {
  swarmer,
  dasher,
  orbiter,
  splitter,
  goliath,
  phantom,
  bossLeviathan,
  bossHydra,
  bossArchitect,
}

class EnemyEntity {
  EnemyEntity({
    required this.id,
    required this.archetype,
    required this.position,
    required this.velocity,
    required this.radius,
    required this.hp,
    required this.maxHp,
    required this.color,
    required this.xpReward,
    required this.scoreReward,
    this.shieldHp = 0,
    this.maxShieldHp = 0,
    this.heading = 0,
    this.phaseTimer = 0,
    this.shootCooldown = 1.5,
    this.isBoss = false,
    this.bossName = '',
    this.bossSubtitle = '',
    this.slowTimer = 0,
  });

  final String id;
  final EnemyArchetype archetype;
  Offset position;
  Offset velocity;
  final double radius;
  double hp;
  final double maxHp;
  final Color color;
  final int xpReward;
  final int scoreReward;
  double shieldHp;
  final double maxShieldHp;
  double heading;
  double phaseTimer;
  double shootCooldown;
  final bool isBoss;
  final String bossName;
  final String bossSubtitle;
  double slowTimer;

  double get hpRatio => maxHp <= 0 ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);
}

class ProjectileEntity {
  ProjectileEntity({
    required this.id,
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.damage,
    required this.isPlayer,
    this.isCrit = false,
    this.pierceLeft = 0,
    this.isHoming = false,
    this.ttl = 2.8,
  });

  final String id;
  Offset position;
  Offset velocity;
  final double radius;
  final Color color;
  final double damage;
  final bool isPlayer;
  final bool isCrit;
  int pierceLeft;
  final bool isHoming;
  double ttl;
  final Set<String> hitEnemyIds = <String>{};
}

class BioCrystalEntity {
  BioCrystalEntity({
    required this.id,
    required this.position,
    required this.velocity,
    required this.xpValue,
    required this.wildCharge,
    required this.color,
    this.isMagnetized = false,
    this.ttl = 14.0,
  });

  final String id;
  Offset position;
  Offset velocity;
  final int xpValue;
  final double wildCharge;
  final Color color;
  bool isMagnetized;
  double ttl;
}

class ParticleEntity {
  ParticleEntity({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
    required this.maxLife,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  double life;
  final double maxLife;

  double get progress => maxLife <= 0 ? 0.0 : (life / maxLife).clamp(0.0, 1.0);
}

class ShockwaveRing {
  ShockwaveRing({
    required this.center,
    required this.maxRadius,
    required this.color,
    this.radius = 8.0,
    this.life = 0.45,
    this.maxLife = 0.45,
    this.strokeWidth = 4.0,
  });

  final Offset center;
  final double maxRadius;
  final Color color;
  double radius;
  double life;
  final double maxLife;
  final double strokeWidth;

  double get alpha => maxLife <= 0 ? 0.0 : (life / maxLife).clamp(0.0, 1.0);
}

class LightningArc {
  LightningArc({
    required this.from,
    required this.to,
    required this.color,
    this.life = 0.18,
  });

  final Offset from;
  final Offset to;
  final Color color;
  double life;
}

class FloatingCombatText {
  FloatingCombatText({
    required this.text,
    required this.position,
    required this.color,
    this.isBig = false,
    this.life = 0.75,
    this.maxLife = 0.75,
  });

  final String text;
  Offset position;
  final Color color;
  final bool isBig;
  double life;
  final double maxLife;

  double get alpha => maxLife <= 0 ? 0.0 : (life / maxLife).clamp(0.0, 1.0);
}

class RunSummaryRecord {
  const RunSummaryRecord({
    required this.hunterName,
    required this.biomeName,
    required this.score,
    required this.waveReached,
    required this.levelReached,
    required this.enemiesSlain,
    required this.bossesSlain,
    required this.maxCombo,
    required this.wildActivations,
  });

  final String hunterName;
  final String biomeName;
  final int score;
  final int waveReached;
  final int levelReached;
  final int enemiesSlain;
  final int bossesSlain;
  final int maxCombo;
  final int wildActivations;
}
