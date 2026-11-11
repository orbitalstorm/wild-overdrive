import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wild_overdrive/engine/wild_game_engine.dart';
import 'package:wild_overdrive/main.dart';
import 'package:wild_overdrive/models/wild_models.dart';

Future<void> _loadRealFlutterFonts() async {
  final String flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/tmp/flutter-sdk/flutter';
  final String fontDir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final Directory dir = Directory(fontDir);
  if (!dir.existsSync()) {
    return;
  }

  final FontLoader robotoLoader = FontLoader('Roboto');
  for (final String file in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-Italic.ttf',
    'Roboto-BoldItalic.ttf',
  ]) {
    final File f = File('$fontDir/$file');
    if (f.existsSync()) {
      final Uint8List bytes = f.readAsBytesSync();
      robotoLoader.addFont(
        Future<ByteData>.value(ByteData.view(bytes.buffer)),
      );
    }
  }
  await robotoLoader.load();

  final File materialIconsFile = File('$fontDir/MaterialIcons-Regular.otf');
  if (materialIconsFile.existsSync()) {
    final FontLoader iconsLoader = FontLoader('MaterialIcons');
    final Uint8List bytes = materialIconsFile.readAsBytesSync();
    iconsLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await iconsLoader.load();
  }
}

Future<void> _captureEmulatorScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath,
) async {
  await tester.pump(const Duration(milliseconds: 120));
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData != null) {
      final File outFile = File(outputPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(byteData.buffer.asUint8List());
    }
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await _loadRealFlutterFonts();
  });

  test(
      'Unit: WildGameEngine classes, GO WILD overdrive, mutations, boss & combat simulation',
      () {
    final WildGameEngine engine = WildGameEngine(randomSeed: 42);
    expect(engine.selectedClass, WildClassId.solarFang);
    expect(engine.enemies, isNotEmpty);
    expect(engine.crystals, isNotEmpty);

    // Step simulation 10 frames
    for (int i = 0; i < 10; i++) {
      engine.step(0.033);
    }
    expect(engine.projectiles, isNotEmpty);

    // Trigger GO WILD Overdrive
    engine.triggerGoWild(forceFull: true);
    expect(engine.isWildActive, isTrue);
    expect(engine.wildActivations, 1);
    expect(engine.combo, greaterThanOrEqualTo(8));
    expect(engine.getOrbitalBladePositions(), isNotEmpty);

    // Open & select a mutation
    engine.openMutationDraft();
    expect(engine.isDraftOpen, isTrue);
    expect(engine.activeDraftChoices.length, 3);
    final MutationId picked = engine.activeDraftChoices.first.id;
    final int beforeStacks = engine.mutationStacks(picked);
    engine.selectMutation(picked);
    expect(engine.isDraftOpen, isFalse);
    expect(engine.mutationStacks(picked), beforeStacks + 1);

    // Spawn colossal boss & trigger Nova Bomb
    engine.spawnBossNow(EnemyArchetype.bossLeviathan);
    expect(engine.activeBoss, isNotNull);
    final double bossInitialHp = engine.activeBoss!.hp;
    engine.triggerNovaBomb();
    expect(engine.activeBoss!.hp, lessThan(bossInitialHp));

    // Switch hunter class & biome
    engine.selectHunterClass(WildClassId.singularityValkyrie);
    expect(engine.hunterSpec.codeName, 'VALKYRIE-Ω');
    engine.selectBiome(WildBiomeId.omegaSingularity);
    expect(engine.biomeSpec.id, WildBiomeId.omegaSingularity);
  });

  testWidgets(
      'Portrait 1080x2400 Full Gameplay, GO WILD Overdrive, Mutations, Boss Rush & Screenshots',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final GlobalKey boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const WildOverdriveApp(
          randomSeed: 777,
          enableRealtimeTicker: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WILD OVERDRIVE'), findsOneWidget);
    expect(find.byKey(const Key('go_wild_button')), findsOneWidget);

    final WildOverdriveScreenState screenState =
        tester.state<WildOverdriveScreenState>(
      find.byType(WildOverdriveScreen),
    );

    // Advance a few combat frames so projectiles, particles, and lightning are mid-flight
    for (int i = 0; i < 6; i++) {
      screenState.engine.step(0.033);
    }
    await tester.pump();

    // Screenshot 01: Neon Jungle Combat Arena
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/01_arena_neon_jungle_combat.png',
    );

    // Tap GO WILD! button to unleash Overdrive
    await tester.tap(find.byKey(const Key('go_wild_button')));
    await tester.pump();
    screenState.engine.step(0.04);
    await tester.pump();

    expect(find.byKey(const Key('wild_active_banner')), findsOneWidget);

    // Screenshot 02: GO WILD! Overdrive active
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/02_go_wild_overdrive_supernova.png',
    );

    // Tap MUTATION button to open the 3-card Mutation Draft overlay
    await tester.tap(find.byKey(const Key('draft_mutation_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mutation_draft_overlay')), findsOneWidget);
    expect(find.byKey(const Key('draft_choice_0')), findsOneWidget);

    // Screenshot 03: Mutation Draft Overlay
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/03_mutation_draft_evolution.png',
    );

    // Select the first mutation card
    await tester.tap(find.byKey(const Key('draft_choice_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mutation_draft_overlay')), findsNothing);

    // Switch to Omega Singularity biome, spawn Colossal Boss, and fire Dash + Supernova
    screenState.engine.selectBiome(WildBiomeId.omegaSingularity);
    await tester.tap(find.byKey(const Key('spawn_boss_button')));
    await tester.pump();
    for (int i = 0; i < 5; i++) {
      screenState.engine.step(0.05);
    }
    await tester.tap(find.byKey(const Key('dash_button')));
    await tester.pump();

    expect(find.byKey(const Key('boss_active_banner')), findsOneWidget);

    // Screenshot 04: Colossal Boss Fight in Omega Singularity
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/04_colossal_boss_leviathan.png',
    );

    // Open Hangar Sheet (Hunter Classes & Biomes)
    await tester.tap(find.byKey(const Key('open_hangar_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('HANGAR DES CHASSEURS APEX & BIOMES'),
      findsOneWidget,
    );

    // Screenshot 05: Hangar Sheet
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/05_hangar_hunters_biomes.png',
    );

    // Close Hangar Sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Open Codex Sheet (18 Synergistic Mutations)
    await tester.tap(find.byKey(const Key('open_codex_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('CODEX DES 18 MUTATIONS & PANTHÉON'),
      findsOneWidget,
    );

    // Screenshot 06: Codex Sheet
    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/06_codex_18_mutations_chaos_lab.png',
    );

    // Close Codex Sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });
}
