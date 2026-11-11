import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'engine/wild_game_engine.dart';
import 'models/wild_models.dart';
import 'painters/wild_arena_painter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF04070E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WildOverdriveApp());
}

class WildOverdriveApp extends StatelessWidget {
  const WildOverdriveApp({
    super.key,
    this.randomSeed,
    this.enableRealtimeTicker = true,
  });

  final int? randomSeed;
  final bool enableRealtimeTicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wild Overdrive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF04070E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF007F),
          secondary: Color(0xFF00FF9D),
          surface: Color(0xFF0B111E),
        ),
        useMaterial3: true,
      ),
      home: WildOverdriveScreen(
        randomSeed: randomSeed,
        enableRealtimeTicker: enableRealtimeTicker,
      ),
    );
  }
}

class WildOverdriveScreen extends StatefulWidget {
  const WildOverdriveScreen({
    super.key,
    this.randomSeed,
    this.enableRealtimeTicker = true,
  });

  final int? randomSeed;
  final bool enableRealtimeTicker;

  @override
  State<WildOverdriveScreen> createState() => WildOverdriveScreenState();
}

class WildOverdriveScreenState extends State<WildOverdriveScreen>
    with SingleTickerProviderStateMixin {
  late final WildGameEngine engine;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  Offset? _dragOrigin;

  @override
  void initState() {
    super.initState();
    engine = WildGameEngine(randomSeed: widget.randomSeed);
    engine.addListener(_onEngineChanged);
    if (widget.enableRealtimeTicker) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onEngineChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final double dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    engine.step(dt);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    engine.removeListener(_onEngineChanged);
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WildHunterSpec hunter = engine.hunterSpec;
    final WildBiomeSpec biome = engine.biomeSpec;
    final EnemyEntity? boss = engine.activeBoss;

    return Scaffold(
      backgroundColor: const Color(0xFF04070E),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTopCommandBar(hunter, biome),
            _buildTelemetryBar(hunter),
            if (boss != null) _buildBossBanner(boss),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      GestureDetector(
                        key: const Key('wild_arena_canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (DragStartDetails details) {
                          _dragOrigin = details.localPosition;
                        },
                        onPanUpdate: (DragUpdateDetails details) {
                          final Offset origin =
                              _dragOrigin ?? details.localPosition;
                          final Offset delta = details.localPosition - origin;
                          engine.setJoystickVector(delta / 36.0);
                        },
                        onPanEnd: (DragEndDetails details) {
                          _dragOrigin = null;
                          engine.setJoystickVector(Offset.zero);
                        },
                        child: CustomPaint(
                          painter: WildArenaPainter(engine: engine),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      // Top-left status pills inside arena
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: Row(
                            children: <Widget>[
                              _buildArenaPill(
                                icon: hunter.icon,
                                label: '${hunter.codeName} ${hunter.title}',
                                color: hunter.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              _buildArenaPill(
                                icon: Icons.auto_awesome_motion_rounded,
                                label: 'CHAOS ×${engine.chaosMultiplier}',
                                color: const Color(0xFF00E5FF),
                              ),
                              const Spacer(),
                              Container(
                                key: const Key('combo_badge'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF140B29)
                                      .withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: engine.combo >= 8
                                        ? const Color(0xFFFFD600)
                                        : const Color(0xFFFF007F),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'COMBO ×${engine.combo}',
                                  style: TextStyle(
                                    color: engine.combo >= 8
                                        ? const Color(0xFFFFD600)
                                        : const Color(0xFFFF4081),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Active GO WILD banner
                      if (engine.isWildActive)
                        Positioned(
                          top: 38,
                          left: 16,
                          right: 16,
                          child: IgnorePointer(
                            child: Container(
                              key: const Key('wild_active_banner'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xDDFF007F),
                                    Color(0xDDFF6D00),
                                    Color(0xDDFFD600),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.4,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'FURIE SAUVAGE ACTIVE : ${hunter.ultimateName} (${engine.wildTimer.toStringAsFixed(1)}s)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Bottom-left active mutations strip inside arena
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: _buildActiveMutationsStrip(),
                        ),
                      ),
                      // Mutation Draft Overlay
                      if (engine.isDraftOpen) _buildMutationDraftOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomControlDock(hunter),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCommandBar(WildHunterSpec hunter, WildBiomeSpec biome) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: const BoxDecoration(
        color: Color(0xFF080D1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1C2942), width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[hunter.primaryColor, hunter.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.whatshot_rounded,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        'WILD OVERDRIVE',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: biome.accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: biome.accentColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'VAGUE ${engine.wave}',
                        key: const Key('wave_badge_text'),
                        style: TextStyle(
                          color: biome.accentColor,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SCORE ${engine.score} • RECORD ${engine.bestScore} • ${biome.name}',
                  key: const Key('score_text'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderIconButton(
            key: const Key('open_hangar_button'),
            icon: Icons.rocket_rounded,
            label: 'HANGAR',
            color: hunter.primaryColor,
            onTap: _showHangarSheet,
          ),
          const SizedBox(width: 5),
          _buildHeaderIconButton(
            key: const Key('open_codex_button'),
            icon: Icons.hub_rounded,
            label: 'CODEX',
            color: const Color(0xFF00FF9D),
            onTap: _showCodexSheet,
          ),
          const SizedBox(width: 5),
          _buildHeaderIconButton(
            key: const Key('open_chaos_lab_button'),
            icon: Icons.science_rounded,
            label: 'CHAOS',
            color: const Color(0xFF00E5FF),
            onTap: _showChaosLabSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBar(WildHunterSpec hunter) {
    final double hpRatio =
        engine.maxHp <= 0 ? 0.0 : (engine.hp / engine.maxHp).clamp(0.0, 1.0);
    final double shieldRatio = engine.maxShield <= 0
        ? 0.0
        : (engine.shield / engine.maxShield).clamp(0.0, 1.0);
    final double xpRatio = engine.xpToNextLevel <= 0
        ? 0.0
        : (engine.xp / engine.xpToNextLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFF060A14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildMiniGauge(
              label: 'COQUE ${engine.hp.round()}/${engine.maxHp.round()}',
              ratio: hpRatio,
              color: const Color(0xFFFF1744),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniGauge(
              label:
                  'BOUCLIER ${engine.shield.round()}/${engine.maxShield.round()}',
              ratio: shieldRatio,
              color: const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniGauge(
              label: 'NIV. ${engine.level} (${engine.totalMutationStacks} MUT.)',
              ratio: xpRatio,
              color: const Color(0xFF00FF9D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGauge({
    required String label,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBossBanner(EnemyEntity boss) {
    return Container(
      key: const Key('boss_active_banner'),
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1F091D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: boss.color, width: 1.3),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: boss.color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${boss.bossName} — ${boss.bossSubtitle}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${boss.hp.round()} PV',
                style: TextStyle(
                  color: boss.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: boss.hpRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFF2D122B),
              valueColor: AlwaysStoppedAnimation<Color>(boss.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArenaPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMutationsStrip() {
    final List<MapEntry<MutationId, int>> entries =
        engine.mutations.entries.where((MapEntry<MutationId, int> e) => e.value > 0).toList();
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: entries.take(5).map((MapEntry<MutationId, int> entry) {
        final MutationSpec spec = MutationSpec.byId(entry.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF090E1A).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: spec.color.withValues(alpha: 0.65)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(spec.icon, color: spec.color, size: 11),
              const SizedBox(width: 3),
              Text(
                '${spec.name} ×${entry.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMutationDraftOverlay() {
    return Container(
      key: const Key('mutation_draft_overlay'),
      color: const Color(0xE6050811),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF9D).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00FF9D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF00FF9D),
                  size: 13,
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'ÉVOLUTION BIO-CYBER : CHOISISSEZ UNE MUTATION SAUVAGE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF00FF9D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: engine.activeDraftChoices.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 7),
              itemBuilder: (BuildContext context, int index) {
                final MutationSpec choice = engine.activeDraftChoices[index];
                final int currentStacks = engine.mutationStacks(choice.id);
                return InkWell(
                  key: Key('draft_choice_$index'),
                  onTap: () => engine.selectMutation(choice.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1628),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: choice.color, width: 1.4),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: choice.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            choice.icon,
                            color: choice.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: choice.color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      choice.rarityLabel,
                                      style: TextStyle(
                                        color: choice.color,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Niv. $currentStacks >> ${currentStacks + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                choice.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                choice.description,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: choice.color,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('reroll_draft_button'),
                  onPressed: engine.rerollMutationDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD600),
                    side: const BorderSide(color: Color(0xFFFFD600)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'RELANCER TIRAGE (${engine.rerollTokens})',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('close_draft_button'),
                onPressed: engine.closeMutationDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text(
                  'FERMER',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlDock(WildHunterSpec hunter) {
    final int wildPercent = (engine.wildMeter * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF080D1A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // GO WILD Overdrive Bar + Trigger Button
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          engine.isWildActive
                              ? 'OVERDRIVE "GO WILD!" EN COURS'
                              : 'JAUGE DE FURIE SAUVAGE (GO WILD!)',
                          style: TextStyle(
                            color: engine.isWildActive
                                ? const Color(0xFFFFD600)
                                : const Color(0xFFFF4081),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$wildPercent%',
                          key: const Key('wild_meter_percent'),
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: engine.wildMeter.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                key: const Key('go_wild_button'),
                onTap: () => engine.triggerGoWild(forceFull: true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFFFF007F),
                        Color(0xFFFF6D00),
                        Color(0xFFFFD600),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFFF007F).withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.bolt_rounded,
                        color: Colors.black,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'GO WILD!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // 4 Tactical Action Buttons
          Row(
            children: <Widget>[
              Expanded(
                child: _buildTacticalButton(
                  key: const Key('dash_button'),
                  icon: Icons.fast_forward_rounded,
                  label: 'DASH PHASIQUE',
                  sublabel: 'Esquive + Sillage',
                  color: const Color(0xFF00E5FF),
                  onTap: engine.triggerDash,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTacticalButton(
                  key: const Key('nova_bomb_button'),
                  icon: Icons.flare_rounded,
                  label: 'SUPERNOVA (${engine.novaBombs})',
                  sublabel: 'Onde Thermique',
                  color: const Color(0xFFFF9100),
                  onTap: engine.triggerNovaBomb,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTacticalButton(
                  key: const Key('draft_mutation_button'),
                  icon: Icons.auto_awesome_rounded,
                  label: 'MUTATION',
                  sublabel: 'Tirage Évolution',
                  color: const Color(0xFF00FF9D),
                  onTap: engine.openMutationDraft,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildTacticalButton(
                  key: const Key('spawn_boss_button'),
                  icon: Icons.crisis_alert_rounded,
                  label: 'BOSS RUSH',
                  sublabel: 'Invoquer Titan',
                  color: const Color(0xFFFF007F),
                  onTap: engine.spawnBossNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalButton({
    required Key key,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 2),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              sublabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHangarSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF090E1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              maxChildSize: 0.92,
              minChildSize: 0.5,
              builder: (BuildContext context, ScrollController scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: Color(0xFFFF007F),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'HANGAR DES CHASSEURS APEX & BIOMES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          children: <Widget>[
                            const Text(
                              'SÉLECTION DU CHASSEUR APEX',
                              style: TextStyle(
                                color: Color(0xFF00FF9D),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...WildHunterSpec.catalog.map((WildHunterSpec spec) {
                              final bool selected =
                                  engine.selectedClass == spec.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? spec.primaryColor.withValues(alpha: 0.16)
                                      : const Color(0xFF11192C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? spec.primaryColor
                                        : const Color(0xFF1E293B),
                                    width: selected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    key: Key('select_hunter_${spec.id.name}'),
                                    onTap: () {
                                      engine.selectHunterClass(spec.id);
                                      setModalState(() {});
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          spec.primaryColor.withValues(alpha: 0.2),
                                      child: Icon(
                                        spec.icon,
                                        color: spec.primaryColor,
                                      ),
                                    ),
                                    title: Text(
                                      '${spec.codeName} — ${spec.title}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${spec.role}\nUltime GO WILD : ${spec.ultimateName}',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    trailing: selected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: spec.primaryColor,
                                          )
                                        : const Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.white38,
                                          ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            const Text(
                              'DIMENSIONS & BIOMES COSMIQUES',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...WildBiomeSpec.catalog.map((WildBiomeSpec b) {
                              final bool selected =
                                  engine.selectedBiome == b.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? b.accentColor.withValues(alpha: 0.16)
                                      : const Color(0xFF11192C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? b.accentColor
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    key: Key('select_biome_${b.id.name}'),
                                    onTap: () {
                                      engine.selectBiome(b.id);
                                      setModalState(() {});
                                    },
                                    title: Text(
                                      '${b.name} (${b.subtitle})',
                                      style: TextStyle(
                                        color: b.accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      b.modifierLabel,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    trailing: selected
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: b.accentColor,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCodexSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF090E1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.80,
              maxChildSize: 0.92,
              minChildSize: 0.5,
              builder: (BuildContext context, ScrollController scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.hub_rounded,
                            color: Color(0xFF00FF9D),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'CODEX DES 18 MUTATIONS & PANTHÉON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const Text(
                        'Appuyez sur une mutation pour l\'injecter immédiatement dans votre Chasseur.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: MutationSpec.catalog.length,
                          itemBuilder: (BuildContext context, int index) {
                            final MutationSpec m = MutationSpec.catalog[index];
                            final int stacks = engine.mutationStacks(m.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11192C),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: stacks > 0
                                      ? m.color
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              child: InkWell(
                                key: Key('codex_mutation_${m.id.name}'),
                                onTap: () {
                                  engine.selectMutation(m.id);
                                  setModalState(() {});
                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(m.icon, color: m.color, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            '${m.name} (${m.rarityLabel})',
                                            style: TextStyle(
                                              color: m.color,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            m.description,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: m.color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Niv. $stacks',
                                        style: TextStyle(
                                          color: m.color,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showChaosLabSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF090E1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'LABORATOIRE CHAOS ("GO WILD" SANDBOX)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DENSITÉ D\'ESSAIM & MULTIPLICATEUR DE CHAOS',
                    style: TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <int>[1, 2, 5].map((int mult) {
                      final bool active = engine.chaosMultiplier == mult;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            key: Key('chaos_mult_$mult'),
                            onPressed: () {
                              engine.setChaosMultiplier(mult);
                              setModalState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active
                                  ? const Color(0xFFFF007F)
                                  : const Color(0xFF162038),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'CHAOS ×$mult',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('god_mode_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bouclier Invulnérable (God Mode Sandbox)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Permet de tester toutes les armes et boss sans perdre la coque.',
                      style: TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                    value: engine.godMode,
                    activeThumbColor: const Color(0xFF00FF9D),
                    onChanged: (_) {
                      engine.toggleGodMode();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'INVOCATION DIRECTE DE BOSS COLOSSAUX',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        key: const Key('spawn_leviathan_btn'),
                        onPressed: () {
                          engine.spawnBossNow(EnemyArchetype.bossLeviathan);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.bug_report_rounded, size: 16),
                        label: const Text('LÉVIATHAN NÉON'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('spawn_hydra_btn'),
                        onPressed: () {
                          engine.spawnBossNow(EnemyArchetype.bossHydra);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                        ),
                        label: const Text('HYDRE SOLAIRE'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('spawn_architect_btn'),
                        onPressed: () {
                          engine.spawnBossNow(EnemyArchetype.bossArchitect);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.blur_circular_rounded, size: 16),
                        label: const Text('ARCHITECTE Ω'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
