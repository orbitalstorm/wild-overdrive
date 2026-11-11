import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/wild_models.dart';

class WildGameEngine extends ChangeNotifier {
  WildGameEngine({int? randomSeed})
      : _rng = math.Random(randomSeed ?? 1337),
        _selectedClass = WildClassId.solarFang,
        _selectedBiome = WildBiomeId.neonJungle {
    resetRun(populateInitialArena: true);
  }

  final math.Random _rng;
  int _entityCounter = 0;

  Size _arenaSize = const Size(360, 520);
  Size get arenaSize => _arenaSize;

  WildClassId _selectedClass;
  WildClassId get selectedClass => _selectedClass;
  WildHunterSpec get hunterSpec => WildHunterSpec.byId(_selectedClass);

  WildBiomeId _selectedBiome;
  WildBiomeId get selectedBiome => _selectedBiome;
  WildBiomeSpec get biomeSpec => WildBiomeSpec.byId(_selectedBiome);

  // Player state
  Offset playerPos = const Offset(180, 340);
  Offset playerVel = Offset.zero;
  Offset joystickVector = Offset.zero;
  double playerHeading = -math.pi / 2;

  double hp = 220;
  double maxHp = 220;
  double shield = 80;
  double maxShield = 80;

  int level = 1;
  int xp = 0;
  int xpToNextLevel = 100;

  int score = 0;
  int bestScore = 18450;
  int wave = 1;
  int combo = 1;
  int maxCombo = 1;
  double comboTimer = 0;
  int enemiesSlain = 0;
  int bossesSlain = 0;
  int wildActivations = 0;

  // GO WILD! Overdrive state
  double wildMeter = 0.65; // 0.0 .. 1.0
  bool isWildActive = false;
  double wildTimer = 0.0;
  double wildMaxDuration = 8.0;

  // Tactical cooldowns & charges
  double dashCooldown = 0.0;
  double invulnerableTimer = 0.0;
  int novaBombs = 3;
  int rerollTokens = 3;

  // Chaos Lab & Autopilot settings
  int chaosMultiplier = 1; // 1, 2, or 5
  bool godMode = false;
  bool autoSteerAssist = true;
  bool isPaused = false;
  bool isGameOver = false;

  // Internal timers
  double _fireAccumulator = 0.0;
  double _waveTimer = 0.0;
  double _spawnAccumulator = 0.0;
  double _homingAccumulator = 0.0;
  double _novaShieldAccumulator = 0.0;
  double _orbitalAngle = 0.0;
  int _salvoCount = 0;
  double elapsedTime = 0.0;
  double screenShake = 0.0;

  // Mutations & Draft state
  final Map<MutationId, int> mutations = <MutationId, int>{};
  List<MutationSpec> activeDraftChoices = <MutationSpec>[];
  bool get isDraftOpen => activeDraftChoices.isNotEmpty;

  // Entities in arena
  final List<EnemyEntity> enemies = <EnemyEntity>[];
  final List<ProjectileEntity> projectiles = <ProjectileEntity>[];
  final List<BioCrystalEntity> crystals = <BioCrystalEntity>[];
  final List<ParticleEntity> particles = <ParticleEntity>[];
  final List<ShockwaveRing> shockwaves = <ShockwaveRing>[];
  final List<LightningArc> lightningArcs = <LightningArc>[];
  final List<FloatingCombatText> floatingTexts = <FloatingCombatText>[];
  final List<RunSummaryRecord> runHistory = <RunSummaryRecord>[
    const RunSummaryRecord(
      hunterName: 'REX-9 SOLAR FANG',
      biomeName: 'JUNGLE BIOLUMINESCENTE',
      score: 18450,
      waveReached: 7,
      levelReached: 9,
      enemiesSlain: 142,
      bossesSlain: 2,
      maxCombo: 18,
      wildActivations: 4,
    ),
    const RunSummaryRecord(
      hunterName: 'VIPER-X VOID PHANTOM',
      biomeName: 'ABYSSE CYBER-QUANTIQUE',
      score: 14920,
      waveReached: 6,
      levelReached: 8,
      enemiesSlain: 118,
      bossesSlain: 1,
      maxCombo: 14,
      wildActivations: 3,
    ),
  ];

  EnemyEntity? get activeBoss {
    for (final EnemyEntity enemy in enemies) {
      if (enemy.isBoss) {
        return enemy;
      }
    }
    return null;
  }

  int mutationStacks(MutationId id) => mutations[id] ?? 0;

  int get totalMutationStacks {
    int sum = 0;
    for (final int count in mutations.values) {
      sum += count;
    }
    return sum;
  }

  void updateArenaSize(Size newSize) {
    if (newSize.width <= 40 || newSize.height <= 40) {
      return;
    }
    if ((_arenaSize.width - newSize.width).abs() < 1 &&
        (_arenaSize.height - newSize.height).abs() < 1) {
      return;
    }
    _arenaSize = newSize;
    playerPos = Offset(
      playerPos.dx.clamp(28.0, _arenaSize.width - 28.0),
      playerPos.dy.clamp(28.0, _arenaSize.height - 28.0),
    );
  }

  void selectHunterClass(WildClassId id) {
    _selectedClass = id;
    resetRun(populateInitialArena: true);
    notifyListeners();
  }

  void selectBiome(WildBiomeId id) {
    _selectedBiome = id;
    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 240,
        color: biomeSpec.accentColor,
        strokeWidth: 5,
      ),
    );
    floatingTexts.add(
      FloatingCombatText(
        text: 'SECTEUR : ${biomeSpec.name}',
        position: playerPos - const Offset(0, 36),
        color: biomeSpec.accentColor,
        isBig: true,
      ),
    );
    notifyListeners();
  }

  void cycleBiome() {
    const List<WildBiomeSpec> all = WildBiomeSpec.catalog;
    final int idx = all.indexWhere((WildBiomeSpec b) => b.id == _selectedBiome);
    final int nextIdx = (idx + 1) % all.length;
    selectBiome(all[nextIdx].id);
  }

  void setChaosMultiplier(int multiplier) {
    chaosMultiplier = multiplier;
    floatingTexts.add(
      FloatingCombatText(
        text: 'CHAOS ×$chaosMultiplier ACTIVÉ !',
        position: playerPos - const Offset(0, 34),
        color: const Color(0xFFFF007F),
        isBig: true,
      ),
    );
    notifyListeners();
  }

  void toggleGodMode() {
    godMode = !godMode;
    if (godMode) {
      hp = maxHp;
      shield = maxShield;
    }
    notifyListeners();
  }

  void toggleAutoSteer() {
    autoSteerAssist = !autoSteerAssist;
    notifyListeners();
  }

  void setJoystickVector(Offset vector) {
    final double mag = vector.distance;
    if (mag > 1.0) {
      joystickVector = vector / mag;
    } else {
      joystickVector = vector;
    }
  }

  void resetRun({bool populateInitialArena = true}) {
    final WildHunterSpec spec = hunterSpec;
    maxHp = spec.maxHp;
    hp = spec.maxHp;
    maxShield = spec.maxShield;
    shield = spec.maxShield;

    level = 1;
    xp = 35;
    xpToNextLevel = 100;
    score = 1250;
    wave = 1;
    combo = 4;
    maxCombo = 4;
    comboTimer = 4.0;
    enemiesSlain = 6;
    bossesSlain = 0;
    wildActivations = 0;

    wildMeter = 0.78;
    isWildActive = false;
    wildTimer = 0.0;
    dashCooldown = 0.0;
    invulnerableTimer = 0.0;
    novaBombs = 3;
    rerollTokens = 3;
    isPaused = false;
    isGameOver = false;
    elapsedTime = 0.0;
    screenShake = 0.0;

    mutations.clear();
    mutations[MutationId.orbitalBlades] = 1;
    mutations[MutationId.chainLightning] = 1;
    activeDraftChoices = <MutationSpec>[];

    enemies.clear();
    projectiles.clear();
    crystals.clear();
    particles.clear();
    shockwaves.clear();
    lightningArcs.clear();
    floatingTexts.clear();

    playerPos = Offset(_arenaSize.width * 0.5, _arenaSize.height * 0.66);
    playerVel = Offset.zero;
    playerHeading = -math.pi / 2;

    if (populateInitialArena) {
      _populateShowcaseArena();
    }
    notifyListeners();
  }

  void _populateShowcaseArena() {
    final double w = _arenaSize.width;
    final double h = _arenaSize.height;

    // Spawn an immediate vibrant combat formation so the arena is alive at startup
    final List<Offset> positions = <Offset>[
      Offset(w * 0.22, h * 0.24),
      Offset(w * 0.78, h * 0.22),
      Offset(w * 0.50, h * 0.18),
      Offset(w * 0.18, h * 0.44),
      Offset(w * 0.82, h * 0.42),
      Offset(w * 0.35, h * 0.32),
      Offset(w * 0.66, h * 0.30),
    ];
    final List<EnemyArchetype> types = <EnemyArchetype>[
      EnemyArchetype.swarmer,
      EnemyArchetype.dasher,
      EnemyArchetype.goliath,
      EnemyArchetype.orbiter,
      EnemyArchetype.splitter,
      EnemyArchetype.phantom,
      EnemyArchetype.swarmer,
    ];

    for (int i = 0; i < positions.length; i++) {
      _spawnEnemyAt(types[i], positions[i]);
    }

    // Spawn a few glowing bio-crystals ready to be magnetized
    for (int i = 0; i < 8; i++) {
      final double angle = (i / 8) * math.pi * 2;
      crystals.add(
        BioCrystalEntity(
          id: 'c_init_$i',
          position: playerPos + Offset(math.cos(angle) * 78, math.sin(angle) * 78),
          velocity: Offset.zero,
          xpValue: 18,
          wildCharge: 0.06,
          color: i.isEven ? const Color(0xFF00FF9D) : const Color(0xFF00E5FF),
        ),
      );
    }

    // Fire an initial salvo of player plasma bolts and a lightning arc
    _firePlayerWeaponSalvo();
    if (enemies.length >= 2) {
      lightningArcs.add(
        LightningArc(
          from: playerPos,
          to: enemies[2].position,
          color: const Color(0xFF00E5FF),
          life: 0.35,
        ),
      );
      lightningArcs.add(
        LightningArc(
          from: enemies[2].position,
          to: enemies[5].position,
          color: const Color(0xFF00FF9D),
          life: 0.35,
        ),
      );
    }

    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 115,
        radius: 54,
        color: hunterSpec.primaryColor,
        strokeWidth: 3.5,
      ),
    );
  }

  String _nextId(String prefix) {
    _entityCounter += 1;
    return '${prefix}_$_entityCounter';
  }

  void _spawnEnemyAt(EnemyArchetype archetype, Offset pos) {
    final double waveScale = 1.0 + (wave - 1) * 0.18;
    switch (archetype) {
      case EnemyArchetype.swarmer:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 13,
            hp: 42 * waveScale,
            maxHp: 42 * waveScale,
            color: const Color(0xFFFF1744),
            xpReward: 16,
            scoreReward: 120,
          ),
        );
      case EnemyArchetype.dasher:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 14,
            hp: 55 * waveScale,
            maxHp: 55 * waveScale,
            color: const Color(0xFFFF9100),
            xpReward: 22,
            scoreReward: 160,
          ),
        );
      case EnemyArchetype.orbiter:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 16,
            hp: 75 * waveScale,
            maxHp: 75 * waveScale,
            color: const Color(0xFF00E5FF),
            xpReward: 28,
            scoreReward: 210,
            shootCooldown: 1.4,
          ),
        );
      case EnemyArchetype.splitter:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 18,
            hp: 88 * waveScale,
            maxHp: 88 * waveScale,
            color: const Color(0xFF00E676),
            xpReward: 32,
            scoreReward: 240,
          ),
        );
      case EnemyArchetype.goliath:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 23,
            hp: 160 * waveScale,
            maxHp: 160 * waveScale,
            shieldHp: 60 * waveScale,
            maxShieldHp: 60 * waveScale,
            color: const Color(0xFF7C4DFF),
            xpReward: 48,
            scoreReward: 380,
          ),
        );
      case EnemyArchetype.phantom:
        enemies.add(
          EnemyEntity(
            id: _nextId('e'),
            archetype: archetype,
            position: pos,
            velocity: Offset.zero,
            radius: 15,
            hp: 68 * waveScale,
            maxHp: 68 * waveScale,
            color: const Color(0xFFE040FB),
            xpReward: 30,
            scoreReward: 250,
          ),
        );
      case EnemyArchetype.bossLeviathan:
      case EnemyArchetype.bossHydra:
      case EnemyArchetype.bossArchitect:
        _spawnBossEntity(archetype, pos);
    }
  }

  void _spawnBossEntity(EnemyArchetype bossType, Offset pos) {
    final double waveScale = 1.0 + (wave - 1) * 0.22;
    String bossName = 'LÉVIATHAN NÉON X-9';
    String bossSubtitle = 'TITAN BIOMÉCANIQUE ABYSSAL';
    Color bossColor = const Color(0xFFFF007F);
    double baseHp = 1200;

    if (bossType == EnemyArchetype.bossHydra) {
      bossName = 'HYDRE SOLAIRE HÉLIOS';
      bossSubtitle = 'SEIGNEUR THERMONUCLÉAIRE';
      bossColor = const Color(0xFFFF6D00);
      baseHp = 1550;
    } else if (bossType == EnemyArchetype.bossArchitect) {
      bossName = 'ARCHITECTE SAUVAGE Ω';
      bossSubtitle = 'ENTITÉ DE SINGULARITÉ SUPRÊME';
      bossColor = const Color(0xFF00E5FF);
      baseHp = 1900;
    }

    enemies.add(
      EnemyEntity(
        id: _nextId('boss'),
        archetype: bossType,
        position: pos,
        velocity: const Offset(48, 0),
        radius: 42,
        hp: baseHp * waveScale,
        maxHp: baseHp * waveScale,
        shieldHp: 280 * waveScale,
        maxShieldHp: 280 * waveScale,
        color: bossColor,
        xpReward: 240,
        scoreReward: 2500,
        isBoss: true,
        bossName: bossName,
        bossSubtitle: bossSubtitle,
        shootCooldown: 0.9,
      ),
    );
  }

  void spawnBossNow([EnemyArchetype? explicitBoss]) {
    // If a boss is already present, focus it or spawn a new one if explicitly requested
    final List<EnemyArchetype> bossTypes = <EnemyArchetype>[
      EnemyArchetype.bossLeviathan,
      EnemyArchetype.bossHydra,
      EnemyArchetype.bossArchitect,
    ];
    final EnemyArchetype chosen =
        explicitBoss ?? bossTypes[(wave - 1) % bossTypes.length];

    // Remove existing boss if any so the new boss takes center stage cleanly
    enemies.removeWhere((EnemyEntity e) => e.isBoss);

    final Offset bossPos = Offset(_arenaSize.width * 0.5, _arenaSize.height * 0.21);
    _spawnBossEntity(chosen, bossPos);
    screenShake = 10.0;
    shockwaves.add(
      ShockwaveRing(
        center: bossPos,
        maxRadius: 210,
        color: const Color(0xFFFF007F),
        strokeWidth: 6.0,
      ),
    );
    floatingTexts.add(
      FloatingCombatText(
        text: 'ALERTE BOSS COLOSSAL !',
        position: bossPos + const Offset(0, 52),
        color: const Color(0xFFFF1744),
        isBig: true,
      ),
    );
    notifyListeners();
  }

  void triggerGoWild({bool forceFull = false}) {
    if (forceFull) {
      wildMeter = 1.0;
    }
    if (!forceFull && wildMeter < 0.25 && !isWildActive) {
      // Fill it up so the user can always experience GO WILD when tapping the button!
      wildMeter = 1.0;
    }

    isWildActive = true;
    final int catalystStacks = mutationStacks(MutationId.wildCatalyst);
    wildMaxDuration = 8.0 + catalystStacks * 3.0;
    wildTimer = wildMaxDuration;
    wildMeter = 1.0;
    wildActivations += 1;
    combo = math.max(combo + 6, 8);
    maxCombo = math.max(maxCombo, combo);
    comboTimer = 6.0;
    screenShake = 12.0;

    // Magnetize all bio-crystals on the map immediately
    for (final BioCrystalEntity crystal in crystals) {
      crystal.isMagnetized = true;
    }

    // Clear enemy bullets and damage nearby enemies with the Ultimate shockwave
    projectiles.removeWhere((ProjectileEntity p) => !p.isPlayer);
    for (final EnemyEntity enemy in enemies) {
      enemy.hp = math.max(1.0, enemy.hp - hunterSpec.baseDamage * 2.2);
      lightningArcs.add(
        LightningArc(
          from: playerPos,
          to: enemy.position,
          color: const Color(0xFFFFD600),
          life: 0.35,
        ),
      );
    }

    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 280,
        color: const Color(0xFFFFD600),
        strokeWidth: 7.0,
      ),
    );
    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 190,
        color: const Color(0xFFFF007F),
        strokeWidth: 5.0,
      ),
    );

    floatingTexts.add(
      FloatingCombatText(
        text: 'GO WILD! ${hunterSpec.ultimateName}',
        position: playerPos - const Offset(0, 42),
        color: const Color(0xFFFFD600),
        isBig: true,
        life: 1.2,
        maxLife: 1.2,
      ),
    );

    _spawnExplosionParticles(playerPos, const Color(0xFFFFD600), count: 28);
    notifyListeners();
  }

  void triggerDash() {
    if (dashCooldown > 0.0) {
      dashCooldown = 0.0;
    }
    final int thrusterStacks = mutationStacks(MutationId.hyperThrusters);
    dashCooldown = math.max(0.45, 1.4 * math.pow(0.78, thrusterStacks));
    invulnerableTimer = 0.55;

    final Offset oldPos = playerPos;
    Offset dashDir = joystickVector.distance > 0.1
        ? joystickVector
        : Offset(math.cos(playerHeading), math.sin(playerHeading));
    if (dashDir.distance < 0.01) {
      dashDir = const Offset(0, -1);
    } else {
      dashDir = dashDir / dashDir.distance;
    }

    playerPos = Offset(
      (playerPos.dx + dashDir.dx * 92.0).clamp(28.0, _arenaSize.width - 28.0),
      (playerPos.dy + dashDir.dy * 92.0).clamp(28.0, _arenaSize.height - 28.0),
    );

    shockwaves.add(
      ShockwaveRing(
        center: oldPos,
        maxRadius: 85,
        color: const Color(0xFF00E5FF),
        strokeWidth: 3.5,
      ),
    );
    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 95,
        color: hunterSpec.primaryColor,
        strokeWidth: 4.0,
      ),
    );

    // Solar afterburner damages enemies near the dash path
    final int afterburnerStacks = mutationStacks(MutationId.solarAfterburner);
    final double dashDmg = (45.0 + afterburnerStacks * 35.0);
    final List<EnemyEntity> dashSnapshot = List<EnemyEntity>.from(enemies);
    for (final EnemyEntity enemy in dashSnapshot) {
      if ((enemy.position - oldPos).distance < 110 ||
          (enemy.position - playerPos).distance < 110) {
        _damageEnemy(enemy, dashDmg, isCrit: true);
      }
    }

    floatingTexts.add(
      FloatingCombatText(
        text: 'DASH PHASIQUE !',
        position: playerPos - const Offset(0, 28),
        color: const Color(0xFF00E5FF),
      ),
    );
    notifyListeners();
  }

  void triggerNovaBomb() {
    if (novaBombs <= 0) {
      novaBombs = 1; // Refill in arcade/sandbox so button is always responsive
    }
    novaBombs -= 1;
    screenShake = 14.0;

    // Vaporize all enemy projectiles
    projectiles.removeWhere((ProjectileEntity p) => !p.isPlayer);

    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 340,
        color: const Color(0xFF00E5FF),
        strokeWidth: 8.0,
      ),
    );
    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 240,
        color: const Color(0xFFFF007F),
        strokeWidth: 5.0,
      ),
    );

    final List<EnemyEntity> snapshot = List<EnemyEntity>.from(enemies);
    for (final EnemyEntity enemy in snapshot) {
      final double dmg = enemy.isBoss ? 520.0 : 220.0;
      _damageEnemy(enemy, dmg, isCrit: true);
    }

    floatingTexts.add(
      FloatingCombatText(
        text: 'SUPERNOVA DÉCLENCHÉE !',
        position: playerPos - const Offset(0, 38),
        color: const Color(0xFF00E5FF),
        isBig: true,
      ),
    );
    notifyListeners();
  }

  void openMutationDraft() {
    final List<MutationSpec> pool = List<MutationSpec>.from(MutationSpec.catalog);
    pool.shuffle(_rng);
    activeDraftChoices = pool.take(3).toList();
    notifyListeners();
  }

  void rerollMutationDraft() {
    if (rerollTokens > 0) {
      rerollTokens -= 1;
    }
    openMutationDraft();
  }

  void selectMutation(MutationId id) {
    final int current = mutations[id] ?? 0;
    mutations[id] = current + 1;
    activeDraftChoices = <MutationSpec>[];

    final MutationSpec spec = MutationSpec.byId(id);
    if (id == MutationId.titanHull) {
      maxHp += 50;
      hp = math.min(maxHp, hp + 65);
      maxShield += 30;
      shield = math.min(maxShield, shield + 30);
    } else if (id == MutationId.wildCatalyst) {
      wildMeter = (wildMeter + 0.35).clamp(0.0, 1.0);
    }

    shockwaves.add(
      ShockwaveRing(
        center: playerPos,
        maxRadius: 150,
        color: spec.color,
        strokeWidth: 4.5,
      ),
    );
    floatingTexts.add(
      FloatingCombatText(
        text: 'MUTATION : ${spec.name.toUpperCase()} (Niv. ${mutations[id]})',
        position: playerPos - const Offset(0, 34),
        color: spec.color,
        isBig: true,
      ),
    );
    notifyListeners();
  }

  void closeMutationDraft() {
    activeDraftChoices = <MutationSpec>[];
    notifyListeners();
  }

  void step(double dt) {
    if (isPaused || isGameOver || isDraftOpen) {
      return;
    }
    final double clampedDt = dt.clamp(0.001, 0.05);
    elapsedTime += clampedDt;
    _orbitalAngle += clampedDt * (isWildActive ? 5.8 : 3.2);

    if (screenShake > 0) {
      screenShake = math.max(0.0, screenShake - clampedDt * 24.0);
    }
    if (dashCooldown > 0) {
      dashCooldown = math.max(0.0, dashCooldown - clampedDt);
    }
    if (invulnerableTimer > 0) {
      invulnerableTimer = math.max(0.0, invulnerableTimer - clampedDt);
    }

    // Combo decay
    if (comboTimer > 0) {
      comboTimer -= clampedDt;
      if (comboTimer <= 0) {
        combo = 1;
      }
    }

    // GO WILD! active countdown
    if (isWildActive) {
      wildTimer -= clampedDt;
      wildMeter = (wildTimer / wildMaxDuration).clamp(0.0, 1.0);
      if (wildTimer <= 0) {
        isWildActive = false;
        wildMeter = 0.15;
      }
    }

    // Passive shield & titan hull regeneration
    final int titanStacks = mutationStacks(MutationId.titanHull);
    if (shield < maxShield) {
      shield = math.min(maxShield, shield + (4.5 + titanStacks * 2.5) * clampedDt);
    }
    if (titanStacks > 0 && hp < maxHp) {
      hp = math.min(maxHp, hp + titanStacks * 3.0 * clampedDt);
    }

    _updatePlayerMovementAndAim(clampedDt);
    _updatePlayerWeapons(clampedDt);
    _updateOrbitalBladesAndShield(clampedDt);
    _updateProjectiles(clampedDt);
    _updateEnemies(clampedDt);
    _updateCrystals(clampedDt);
    _updateVisualEffects(clampedDt);
    _updateWaveDirector(clampedDt);

    notifyListeners();
  }

  void _updatePlayerMovementAndAim(double dt) {
    final int thrusterStacks = mutationStacks(MutationId.hyperThrusters);
    final double speedMult =
        (1.0 + thrusterStacks * 0.22) * (isWildActive ? 1.35 : 1.0);
    final double moveSpeed = hunterSpec.speed * speedMult;

    Offset moveInput = joystickVector;
    if (moveInput.distance < 0.05 && autoSteerAssist) {
      // Subtle smart-evasion & crystal gathering orbit when thumb is lifted
      Offset steer = Offset.zero;
      for (final EnemyEntity enemy in enemies) {
        final Offset diff = playerPos - enemy.position;
        final double dist = diff.distance;
        if (dist > 1 && dist < 115) {
          steer += (diff / dist) * ((115 - dist) / 115) * 1.4;
        }
      }
      // Gently drift toward arena center so ship never gets stuck in corners
      final Offset center = Offset(_arenaSize.width * 0.5, _arenaSize.height * 0.62);
      final Offset toCenter = center - playerPos;
      if (toCenter.distance > 90) {
        steer += (toCenter / toCenter.distance) * 0.45;
      }
      if (steer.distance > 0.05) {
        moveInput = steer / math.max(1.0, steer.distance);
      }
    }

    playerVel = moveInput * moveSpeed;
    playerPos = Offset(
      (playerPos.dx + playerVel.dx * dt).clamp(26.0, _arenaSize.width - 26.0),
      (playerPos.dy + playerVel.dy * dt).clamp(26.0, _arenaSize.height - 26.0),
    );

    // Smart auto-aim toward closest priority target
    final EnemyEntity? target = _findNearestEnemy(playerPos);
    if (target != null) {
      final Offset d = target.position - playerPos;
      playerHeading = math.atan2(d.dy, d.dx);
    } else if (moveInput.distance > 0.1) {
      playerHeading = math.atan2(moveInput.dy, moveInput.dx);
    } else {
      playerHeading = -math.pi / 2;
    }
  }

  EnemyEntity? _findNearestEnemy(Offset from, {Set<String>? excludeIds}) {
    EnemyEntity? best;
    double bestDist = double.infinity;
    for (final EnemyEntity enemy in enemies) {
      if (excludeIds != null && excludeIds.contains(enemy.id)) {
        continue;
      }
      final double d = (enemy.position - from).distance;
      if (d < bestDist) {
        bestDist = d;
        best = enemy;
      }
    }
    return best;
  }

  void _updatePlayerWeapons(double dt) {
    final double fireRate =
        hunterSpec.fireRatePerSec * (isWildActive ? 2.6 : 1.0);
    final double interval = 1.0 / fireRate;
    _fireAccumulator += dt;
    while (_fireAccumulator >= interval) {
      _fireAccumulator -= interval;
      _firePlayerWeaponSalvo();
    }

    // Homing Swarm missiles
    final int swarmStacks = mutationStacks(MutationId.homingSwarm);
    if (swarmStacks > 0 || isWildActive) {
      _homingAccumulator += dt;
      final double swarmInterval = math.max(0.55, 1.45 - swarmStacks * 0.2);
      if (_homingAccumulator >= swarmInterval && enemies.isNotEmpty) {
        _homingAccumulator = 0.0;
        final int rocketCount = 2 + swarmStacks;
        for (int i = 0; i < rocketCount; i++) {
          final double spreadAngle =
              playerHeading + (i - (rocketCount - 1) / 2.0) * 0.35;
          projectiles.add(
            ProjectileEntity(
              id: _nextId('p_homing'),
              position: playerPos,
              velocity: Offset(
                math.cos(spreadAngle) * 340,
                math.sin(spreadAngle) * 340,
              ),
              radius: 5.5,
              color: const Color(0xFFFF9100),
              damage: hunterSpec.baseDamage * 0.95,
              isPlayer: true,
              isHoming: true,
            ),
          );
        }
      }
    }
  }

  void _firePlayerWeaponSalvo() {
    _salvoCount += 1;
    final WildHunterSpec spec = hunterSpec;
    final int ricochetStacks = mutationStacks(MutationId.plasmaRicochet);
    final int critStacks = mutationStacks(MutationId.criticalOvercharge);
    final double critChance =
        0.12 + critStacks * 0.20 + (isWildActive ? 0.25 : 0.0);
    final bool isCrit = _rng.nextDouble() < critChance;

    final double baseDmg = spec.baseDamage *
        (isWildActive ? 1.65 : 1.0) *
        (isCrit ? 2.4 : 1.0);
    final double speed = 480.0 * (1.0 + ricochetStacks * 0.16);
    final int pierce = ricochetStacks +
        (spec.weaponPattern == WeaponPattern.piercingRailgun ? 2 : 0) +
        (isWildActive ? 1 : 0);

    final Offset forward =
        Offset(math.cos(playerHeading), math.sin(playerHeading));
    final Offset perp = Offset(-forward.dy, forward.dx);

    switch (spec.weaponPattern) {
      case WeaponPattern.twinPlasma:
        for (final double side in <double>[-9.0, 9.0]) {
          projectiles.add(
            ProjectileEntity(
              id: _nextId('p'),
              position: playerPos + perp * side,
              velocity: forward * speed,
              radius: isCrit ? 6.5 : 5.0,
              color: isCrit ? const Color(0xFFFFEA00) : spec.primaryColor,
              damage: baseDmg,
              isPlayer: true,
              isCrit: isCrit,
              pierceLeft: pierce,
            ),
          );
        }
      case WeaponPattern.piercingRailgun:
        projectiles.add(
          ProjectileEntity(
            id: _nextId('p'),
            position: playerPos + forward * 14,
            velocity: forward * (speed * 1.28),
            radius: 6.5,
            color: const Color(0xFF00E5FF),
            damage: baseDmg * 1.35,
            isPlayer: true,
            isCrit: isCrit,
            pierceLeft: pierce + 2,
          ),
        );
      case WeaponPattern.teslaChain:
        for (final double angleOffset in <double>[-0.14, 0.0, 0.14]) {
          final double a = playerHeading + angleOffset;
          projectiles.add(
            ProjectileEntity(
              id: _nextId('p'),
              position: playerPos,
              velocity: Offset(math.cos(a) * speed, math.sin(a) * speed),
              radius: 5.5,
              color: const Color(0xFF00FF9D),
              damage: baseDmg * 0.82,
              isPlayer: true,
              isCrit: isCrit,
              pierceLeft: pierce,
            ),
          );
        }
      case WeaponPattern.gravitonBlades:
        for (final double angleOffset in <double>[-0.22, 0.22]) {
          final double a = playerHeading + angleOffset;
          projectiles.add(
            ProjectileEntity(
              id: _nextId('p'),
              position: playerPos,
              velocity: Offset(math.cos(a) * speed, math.sin(a) * speed),
              radius: 7.0,
              color: const Color(0xFFFF007F),
              damage: baseDmg * 1.05,
              isPlayer: true,
              isCrit: isCrit,
              pierceLeft: pierce + 1,
              isHoming: true,
            ),
          );
        }
    }

    // Twin Drone Wingmen mutation
    final int wingmenStacks = mutationStacks(MutationId.twinDroneWingmen);
    if (wingmenStacks > 0 || isWildActive) {
      for (final double side in <double>[-28.0, 28.0]) {
        final Offset dronePos = playerPos + perp * side;
        projectiles.add(
          ProjectileEntity(
            id: _nextId('p_drone'),
            position: dronePos,
            velocity: forward * speed,
            radius: 4.2,
            color: const Color(0xFF00FF9D),
            damage: baseDmg * (0.45 + wingmenStacks * 0.15),
            isPlayer: true,
            pierceLeft: ricochetStacks,
          ),
        );
      }
    }

    // Omni Barrage 360° mutation (or during GO WILD every 5 salvos)
    final int omniStacks = mutationStacks(MutationId.omniBarrage);
    if ((omniStacks > 0 || isWildActive) && _salvoCount % 5 == 0) {
      final int bolts = 8 + omniStacks * 2;
      for (int i = 0; i < bolts; i++) {
        final double a = (i / bolts) * math.pi * 2 + _orbitalAngle;
        projectiles.add(
          ProjectileEntity(
            id: _nextId('p_omni'),
            position: playerPos,
            velocity: Offset(math.cos(a) * 390, math.sin(a) * 390),
            radius: 4.8,
            color: const Color(0xFFFF4081),
            damage: baseDmg * 0.7,
            isPlayer: true,
          ),
        );
      }
    }
  }

  List<Offset> getOrbitalBladePositions() {
    final int bladeStacks = mutationStacks(MutationId.orbitalBlades);
    final int count = bladeStacks > 0
        ? (2 + bladeStacks)
        : (isWildActive ? 4 : 0);
    if (count <= 0) {
      return const <Offset>[];
    }
    const double orbitRadius = 56.0;
    final List<Offset> result = <Offset>[];
    for (int i = 0; i < count; i++) {
      final double a = _orbitalAngle + (i / count) * math.pi * 2;
      result.add(
        playerPos + Offset(math.cos(a) * orbitRadius, math.sin(a) * orbitRadius),
      );
    }
    return result;
  }

  void _updateOrbitalBladesAndShield(double dt) {
    final List<Offset> blades = getOrbitalBladePositions();
    if (blades.isNotEmpty) {
      final List<EnemyEntity> snapshot = List<EnemyEntity>.from(enemies);
      for (final EnemyEntity enemy in snapshot) {
        for (final Offset bladePos in blades) {
          if ((enemy.position - bladePos).distance <= enemy.radius + 12.0) {
            _damageEnemy(enemy, 95.0 * dt);
          }
        }
      }
    }

    // Nova Shield pulse
    final int shieldStacks = mutationStacks(MutationId.novaShield);
    if (shieldStacks > 0) {
      _novaShieldAccumulator += dt;
      if (_novaShieldAccumulator >= math.max(2.2, 4.5 - shieldStacks * 0.6)) {
        _novaShieldAccumulator = 0.0;
        projectiles.removeWhere(
          (ProjectileEntity p) =>
              !p.isPlayer && (p.position - playerPos).distance < 110,
        );
        shockwaves.add(
          ShockwaveRing(
            center: playerPos,
            maxRadius: 110,
            color: const Color(0xFF40C4FF),
            strokeWidth: 3.0,
          ),
        );
      }
    }
  }

  void _updateProjectiles(double dt) {
    for (int i = projectiles.length - 1; i >= 0; i--) {
      final ProjectileEntity p = projectiles[i];
      p.ttl -= dt;
      if (p.ttl <= 0) {
        projectiles.removeAt(i);
        continue;
      }

      if (p.isPlayer && p.isHoming && enemies.isNotEmpty) {
        final EnemyEntity? target =
            _findNearestEnemy(p.position, excludeIds: p.hitEnemyIds);
        if (target != null) {
          final Offset desired = target.position - p.position;
          if (desired.distance > 1) {
            final double speed = p.velocity.distance;
            final Offset desiredVel = (desired / desired.distance) * speed;
            p.velocity = Offset.lerp(p.velocity, desiredVel, (dt * 7.5).clamp(0.0, 1.0))!;
          }
        }
      }

      p.position += p.velocity * dt;

      // Out of bounds check
      if (p.position.dx < -30 ||
          p.position.dx > _arenaSize.width + 30 ||
          p.position.dy < -30 ||
          p.position.dy > _arenaSize.height + 30) {
        projectiles.removeAt(i);
        continue;
      }

      if (p.isPlayer) {
        bool consumed = false;
        for (int j = enemies.length - 1; j >= 0; j--) {
          final EnemyEntity enemy = enemies[j];
          if (p.hitEnemyIds.contains(enemy.id)) {
            continue;
          }
          if ((enemy.position - p.position).distance <= enemy.radius + p.radius) {
            p.hitEnemyIds.add(enemy.id);
            _damageEnemy(enemy, p.damage, isCrit: p.isCrit);

            // Chain lightning mutation or Storm Kraken passive
            final int teslaStacks = mutationStacks(MutationId.chainLightning) +
                (_selectedClass == WildClassId.stormKraken ? 1 : 0);
            if (teslaStacks > 0) {
              _triggerChainLightning(enemy, p.damage * 0.55, hops: teslaStacks + 1);
            }

            if (p.pierceLeft > 0) {
              p.pierceLeft -= 1;
            } else {
              consumed = true;
              break;
            }
          }
        }
        if (consumed) {
          projectiles.removeAt(i);
        }
      } else {
        // Enemy projectile hitting player
        if ((p.position - playerPos).distance <= p.radius + 14.0) {
          projectiles.removeAt(i);
          _damagePlayer(p.damage);
        }
      }
    }
  }

  void _triggerChainLightning(EnemyEntity source, double dmg, {required int hops}) {
    final Set<String> visited = <String>{source.id};
    EnemyEntity current = source;
    for (int h = 0; h < hops; h++) {
      final EnemyEntity? next =
          _findNearestEnemy(current.position, excludeIds: visited);
      if (next == null || (next.position - current.position).distance > 145) {
        break;
      }
      visited.add(next.id);
      lightningArcs.add(
        LightningArc(
          from: current.position,
          to: next.position,
          color: const Color(0xFF00E5FF),
        ),
      );
      _damageEnemy(next, dmg);
      current = next;
    }
  }

  void _damageEnemy(EnemyEntity enemy, double rawDamage, {bool isCrit = false}) {
    if (!enemies.contains(enemy)) {
      return;
    }

    final int cryoStacks = mutationStacks(MutationId.cryoStasis);
    if (cryoStacks > 0) {
      enemy.slowTimer = 2.0;
    }

    final int execStacks = mutationStacks(MutationId.omegaExecution);
    double dmg = rawDamage * (1.0 + (cryoStacks > 0 ? 0.15 : 0.0));
    if (enemy.isBoss && execStacks > 0) {
      dmg *= 1.35;
    }

    if (enemy.shieldHp > 0) {
      final double absorbed = math.min(enemy.shieldHp, dmg);
      enemy.shieldHp -= absorbed;
      dmg -= absorbed;
    }
    enemy.hp -= dmg;

    // Omega Execution instant kill on non-boss below 20% HP
    if (!enemy.isBoss && execStacks > 0 && enemy.hpRatio < 0.20) {
      enemy.hp = 0;
    }

    if (isCrit && dmg >= 25) {
      floatingTexts.add(
        FloatingCombatText(
          text: 'CRIT ${dmg.round()}!',
          position: enemy.position - Offset(0, enemy.radius + 6),
          color: const Color(0xFFFFEA00),
        ),
      );
    }

    if (enemy.hp <= 0) {
      _handleEnemyDeath(enemy);
    }
  }

  void _handleEnemyDeath(EnemyEntity enemy) {
    enemies.remove(enemy);
    enemiesSlain += 1;
    if (enemy.isBoss) {
      bossesSlain += 1;
      novaBombs = math.min(5, novaBombs + 1);
      screenShake = 15.0;
      shockwaves.add(
        ShockwaveRing(
          center: enemy.position,
          maxRadius: 260,
          color: enemy.color,
          strokeWidth: 7.0,
        ),
      );
      floatingTexts.add(
        FloatingCombatText(
          text: '👑 BOSS TERRASSÉ ! +${enemy.scoreReward} PTS 👑',
          position: enemy.position,
          color: const Color(0xFFFFD600),
          isBig: true,
          life: 1.3,
          maxLife: 1.3,
        ),
      );
    }

    // Combo & Score
    combo += enemy.isBoss ? 5 : 1;
    maxCombo = math.max(maxCombo, combo);
    comboTimer = 4.5;
    final int biomeScoreMult =
        _selectedBiome == WildBiomeId.omegaSingularity ? 2 : 1;
    final int cappedCombo = combo > 16 ? 16 : combo;
    final int points = enemy.scoreReward * cappedCombo * biomeScoreMult;
    score += points;
    if (score > bestScore) {
      bestScore = score;
    }

    // Vampiric Fury heal
    final int vampStacks = mutationStacks(MutationId.vampiricFury);
    if (vampStacks > 0) {
      final double heal = vampStacks * 4.0 * (isWildActive ? 2.0 : 1.0);
      hp = math.min(maxHp, hp + heal);
    }

    // Singularity Core pull
    if (mutationStacks(MutationId.singularityCore) > 0 ||
        _selectedClass == WildClassId.singularityValkyrie) {
      for (final EnemyEntity other in enemies) {
        final Offset diff = enemy.position - other.position;
        if (diff.distance > 4 && diff.distance < 120) {
          other.position += (diff / diff.distance) * 18.0;
        }
      }
      shockwaves.add(
        ShockwaveRing(
          center: enemy.position,
          maxRadius: 72,
          color: const Color(0xFFE040FB),
          strokeWidth: 2.5,
        ),
      );
    }

    // Splitter spawns 2 mini swarmers on death
    if (enemy.archetype == EnemyArchetype.splitter && enemies.length < 28) {
      for (final double offset in <double>[-16.0, 16.0]) {
        enemies.add(
          EnemyEntity(
            id: _nextId('e_mini'),
            archetype: EnemyArchetype.swarmer,
            position: enemy.position + Offset(offset, 0),
            velocity: Offset.zero,
            radius: 10,
            hp: 25,
            maxHp: 25,
            color: const Color(0xFF69F0AE),
            xpReward: 10,
            scoreReward: 75,
          ),
        );
      }
    }

    // Drop bio-crystals
    final int crystalCount = enemy.isBoss ? 10 : 1;
    for (int c = 0; c < crystalCount; c++) {
      final Offset jitter = crystalCount == 1
          ? Offset.zero
          : Offset(
              (_rng.nextDouble() - 0.5) * 70,
              (_rng.nextDouble() - 0.5) * 70,
            );
      crystals.add(
        BioCrystalEntity(
          id: _nextId('c'),
          position: enemy.position + jitter,
          velocity: Offset.zero,
          xpValue: enemy.isBoss ? 35 : enemy.xpReward,
          wildCharge: enemy.isBoss ? 0.12 : 0.055,
          color: enemy.isBoss
              ? const Color(0xFFFFD600)
              : const Color(0xFF00FF9D),
          isMagnetized: isWildActive,
        ),
      );
    }

    _spawnExplosionParticles(
      enemy.position,
      enemy.color,
      count: enemy.isBoss ? 34 : 10,
    );
  }

  void _damagePlayer(double rawDmg) {
    if (godMode || invulnerableTimer > 0 || isWildActive) {
      return;
    }
    invulnerableTimer = 0.35;
    screenShake = 6.0;
    double dmg = rawDmg;
    if (shield > 0) {
      final double absorbed = math.min(shield, dmg);
      shield -= absorbed;
      dmg -= absorbed;
    }
    hp = math.max(0.0, hp - dmg);

    if (hp <= 0) {
      // Auto Second-Wind in Wild Overdrive or record summary
      if (wildMeter >= 0.5) {
        hp = maxHp * 0.65;
        shield = maxShield;
        triggerGoWild(forceFull: true);
        floatingTexts.add(
          FloatingCombatText(
            text: '🔥 RENAISSANCE SAUVAGE ! 🔥',
            position: playerPos - const Offset(0, 44),
            color: const Color(0xFFFFD600),
            isBig: true,
          ),
        );
      } else {
        hp = maxHp * 0.5;
        shield = maxShield * 0.5;
        runHistory.insert(
          0,
          RunSummaryRecord(
            hunterName: '${hunterSpec.codeName} ${hunterSpec.title}',
            biomeName: biomeSpec.name,
            score: score,
            waveReached: wave,
            levelReached: level,
            enemiesSlain: enemiesSlain,
            bossesSlain: bossesSlain,
            maxCombo: maxCombo,
            wildActivations: wildActivations,
          ),
        );
      }
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final EnemyEntity enemy = enemies[i];
      enemy.phaseTimer += dt;
      if (enemy.slowTimer > 0) {
        enemy.slowTimer = math.max(0.0, enemy.slowTimer - dt);
      }

      final double slowFactor =
          (enemy.slowTimer > 0 ? 0.68 : 1.0) *
          (isWildActive && _selectedClass == WildClassId.voidPhantom ? 0.45 : 1.0);

      final Offset toPlayer = playerPos - enemy.position;
      final double dist = toPlayer.distance;
      final Offset dir = dist > 1 ? toPlayer / dist : const Offset(0, 1);
      enemy.heading = math.atan2(dir.dy, dir.dx);

      if (enemy.isBoss) {
        // Boss weaves horizontally in top third of arena and fires radial patterns
        final double targetY = _arenaSize.height * 0.22;
        final double dy = (targetY - enemy.position.dy) * 2.0;
        double vx = enemy.velocity.dx;
        if (vx.abs() < 20) {
          vx = 56.0;
        }
        if (enemy.position.dx < 60) {
          vx = 56.0;
        } else if (enemy.position.dx > _arenaSize.width - 60) {
          vx = -56.0;
        }
        enemy.velocity = Offset(vx, dy);
        enemy.position += enemy.velocity * dt * slowFactor;

        enemy.shootCooldown -= dt * slowFactor;
        if (enemy.shootCooldown <= 0) {
          enemy.shootCooldown = 1.35;
          const int count = 8;
          for (int k = 0; k < count; k++) {
            final double a = enemy.phaseTimer + (k / count) * math.pi * 2;
            projectiles.add(
              ProjectileEntity(
                id: _nextId('ep_boss'),
                position: enemy.position,
                velocity: Offset(math.cos(a) * 165, math.sin(a) * 165),
                radius: 5.5,
                color: enemy.color,
                damage: 18.0,
                isPlayer: false,
              ),
            );
          }
        }
      } else {
        double speed = 68.0;
        if (enemy.archetype == EnemyArchetype.dasher) {
          speed = 112.0;
        } else if (enemy.archetype == EnemyArchetype.goliath) {
          speed = 44.0;
        } else if (enemy.archetype == EnemyArchetype.orbiter) {
          speed = dist > 150 ? 72.0 : 25.0;
        }
        enemy.velocity = dir * speed * slowFactor;
        enemy.position += enemy.velocity * dt;

        if (enemy.archetype == EnemyArchetype.orbiter) {
          enemy.shootCooldown -= dt * slowFactor;
          if (enemy.shootCooldown <= 0) {
            enemy.shootCooldown = 2.2;
            projectiles.add(
              ProjectileEntity(
                id: _nextId('ep'),
                position: enemy.position,
                velocity: dir * 185.0,
                radius: 4.5,
                color: const Color(0xFFFF1744),
                damage: 12.0,
                isPlayer: false,
              ),
            );
          }
        }
      }

      // Contact collision with player
      if ((enemy.position - playerPos).distance <= enemy.radius + 16.0) {
        _damagePlayer(enemy.isBoss ? 24.0 : 14.0);
        if (!enemy.isBoss) {
          _damageEnemy(enemy, 35.0);
        }
      }
    }
  }

  void _updateCrystals(double dt) {
    final int magnetStacks = mutationStacks(MutationId.voraciousMagnet);
    final double magnetRadius =
        (95.0 + magnetStacks * 65.0) * (isWildActive ? 4.0 : 1.0);

    for (int i = crystals.length - 1; i >= 0; i--) {
      final BioCrystalEntity c = crystals[i];
      c.ttl -= dt;
      if (c.ttl <= 0) {
        crystals.removeAt(i);
        continue;
      }

      final Offset toPlayer = playerPos - c.position;
      final double dist = toPlayer.distance;
      if (dist <= magnetRadius || isWildActive) {
        c.isMagnetized = true;
      }

      if (c.isMagnetized && dist > 1) {
        c.position += (toPlayer / dist) * 380.0 * dt;
      }

      if (dist <= 22.0) {
        crystals.removeAt(i);
        _collectCrystal(c);
      }
    }
  }

  void _collectCrystal(BioCrystalEntity crystal) {
    final int magnetStacks = mutationStacks(MutationId.voraciousMagnet);
    final int catalystStacks = mutationStacks(MutationId.wildCatalyst);

    final int gainedXp =
        (crystal.xpValue * (1.0 + magnetStacks * 0.25)).round();
    xp += gainedXp;

    if (!isWildActive) {
      final double chargeMult =
          (1.0 + catalystStacks * 0.40) *
          (_selectedBiome == WildBiomeId.quantumAbyss ? 1.3 : 1.0);
      wildMeter = (wildMeter + crystal.wildCharge * chargeMult).clamp(0.0, 1.0);
    }

    // Crystal Alchemy fires a bonus bolt at nearest enemy
    if (mutationStacks(MutationId.crystalAlchemy) > 0 && enemies.isNotEmpty) {
      final EnemyEntity? target = _findNearestEnemy(playerPos);
      if (target != null) {
        final Offset d = target.position - playerPos;
        if (d.distance > 1) {
          projectiles.add(
            ProjectileEntity(
              id: _nextId('p_alch'),
              position: playerPos,
              velocity: (d / d.distance) * 440.0,
              radius: 4.5,
              color: const Color(0xFF64FFDA),
              damage: hunterSpec.baseDamage * 0.75,
              isPlayer: true,
            ),
          );
        }
      }
    }

    if (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level += 1;
      xpToNextLevel = (xpToNextLevel * 1.25).round();
      shockwaves.add(
        ShockwaveRing(
          center: playerPos,
          maxRadius: 165,
          color: const Color(0xFF00FF9D),
          strokeWidth: 4.5,
        ),
      );
      floatingTexts.add(
        FloatingCombatText(
          text: 'NIVEAU $level ATTEINT !',
          position: playerPos - const Offset(0, 32),
          color: const Color(0xFF00FF9D),
          isBig: true,
        ),
      );
    }
  }

  void _updateVisualEffects(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final ParticleEntity p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
      } else {
        p.position += p.velocity * dt;
        p.velocity = p.velocity * 0.94;
      }
    }

    for (int i = shockwaves.length - 1; i >= 0; i--) {
      final ShockwaveRing s = shockwaves[i];
      s.life -= dt;
      if (s.life <= 0) {
        shockwaves.removeAt(i);
      } else {
        final double t = 1.0 - (s.life / s.maxLife).clamp(0.0, 1.0);
        s.radius = uiLerp(10.0, s.maxRadius, t);
      }
    }

    for (int i = lightningArcs.length - 1; i >= 0; i--) {
      final LightningArc arc = lightningArcs[i];
      arc.life -= dt;
      if (arc.life <= 0) {
        lightningArcs.removeAt(i);
      }
    }

    for (int i = floatingTexts.length - 1; i >= 0; i--) {
      final FloatingCombatText ft = floatingTexts[i];
      ft.life -= dt;
      if (ft.life <= 0) {
        floatingTexts.removeAt(i);
      } else {
        ft.position -= Offset(0, 28.0 * dt);
      }
    }
  }

  double uiLerp(double a, double b, double t) => a + (b - a) * t;

  void _updateWaveDirector(double dt) {
    _waveTimer += dt;
    if (_waveTimer >= 16.0) {
      _waveTimer = 0.0;
      wave += 1;
      if (wave % 3 == 0 && activeBoss == null) {
        spawnBossNow();
      } else {
        floatingTexts.add(
          FloatingCombatText(
            text: 'VAGUE $wave — ASSAUT SAUVAGE',
            position: Offset(_arenaSize.width * 0.5, _arenaSize.height * 0.35),
            color: biomeSpec.accentColor,
            isBig: true,
          ),
        );
      }
    }

    _spawnAccumulator += dt * chaosMultiplier;
    final int maxEnemiesAllowed = 10 + chaosMultiplier * 5;
    if (_spawnAccumulator >= 1.15 && enemies.length < maxEnemiesAllowed) {
      _spawnAccumulator = 0.0;
      _spawnRandomEdgeEnemy();
    }
  }

  void _spawnRandomEdgeEnemy() {
    final List<EnemyArchetype> pool = <EnemyArchetype>[
      EnemyArchetype.swarmer,
      EnemyArchetype.swarmer,
      EnemyArchetype.dasher,
      EnemyArchetype.orbiter,
      EnemyArchetype.splitter,
      EnemyArchetype.goliath,
      EnemyArchetype.phantom,
    ];
    final EnemyArchetype chosen = pool[_rng.nextInt(pool.length)];

    final int edge = _rng.nextInt(3); // Top, Left, or Right edge
    Offset pos;
    if (edge == 0) {
      pos = Offset(24.0 + _rng.nextDouble() * (_arenaSize.width - 48.0), 28.0);
    } else if (edge == 1) {
      pos = Offset(24.0, 40.0 + _rng.nextDouble() * (_arenaSize.height * 0.55));
    } else {
      pos = Offset(
        _arenaSize.width - 24.0,
        40.0 + _rng.nextDouble() * (_arenaSize.height * 0.55),
      );
    }
    _spawnEnemyAt(chosen, pos);
  }

  void _spawnExplosionParticles(Offset origin, Color color, {int count = 12}) {
    for (int i = 0; i < count; i++) {
      final double a = _rng.nextDouble() * math.pi * 2;
      final double spd = 45.0 + _rng.nextDouble() * 155.0;
      particles.add(
        ParticleEntity(
          position: origin,
          velocity: Offset(math.cos(a) * spd, math.sin(a) * spd),
          color: color,
          radius: 2.5 + _rng.nextDouble() * 3.0,
          life: 0.45,
          maxLife: 0.45,
        ),
      );
    }
  }
}
