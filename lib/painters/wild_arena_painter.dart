import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/wild_game_engine.dart';
import '../models/wild_models.dart';

class WildArenaPainter extends CustomPainter {
  WildArenaPainter({required this.engine}) : super(repaint: engine);

  final WildGameEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    engine.updateArenaSize(size);

    canvas.save();
    if (engine.screenShake > 0.2) {
      final double dx =
          math.sin(engine.elapsedTime * 65.0) * engine.screenShake * 0.45;
      final double dy =
          math.cos(engine.elapsedTime * 52.0) * engine.screenShake * 0.45;
      canvas.translate(dx, dy);
    }

    _drawBiomeBackground(canvas, size);
    _drawCyberGrid(canvas, size);
    if (engine.isWildActive) {
      _drawWildOverdriveAura(canvas, size);
    }
    _drawCrystals(canvas);
    _drawShockwaves(canvas);
    _drawLightningArcs(canvas);
    _drawProjectiles(canvas);
    _drawEnemies(canvas);
    _drawPlayerAndOrbitalSystems(canvas);
    _drawParticles(canvas);
    _drawFloatingTexts(canvas, size);
    _drawTouchJoystickOverlay(canvas, size);

    canvas.restore();
  }

  void _drawBiomeBackground(Canvas canvas, Size size) {
    final WildBiomeSpec biome = engine.biomeSpec;
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          biome.bgTop,
          biome.bgBottom,
          const Color(0xFF03050A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Nebula radial glows
    final Paint nebulaPaint1 = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          biome.nebulaColor.withValues(alpha: 0.22),
          biome.nebulaColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.25, size.height * 0.28),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.28),
      size.width * 0.55,
      nebulaPaint1,
    );

    final Paint nebulaPaint2 = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          biome.accentColor.withValues(alpha: 0.16),
          biome.accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.68),
          radius: size.width * 0.50,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.68),
      size.width * 0.50,
      nebulaPaint2,
    );

    // Parallax starfield
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 36; i++) {
      final double sx = ((i * 73.0 + 19.0) % size.width);
      final double speed = (i % 3 + 1) * 14.0;
      final double sy =
          ((i * 113.0 + engine.elapsedTime * speed) % size.height);
      final double radius = (i % 3 == 0) ? 1.8 : 1.1;
      starPaint.color = Colors.white.withValues(alpha: (i % 4 + 2) * 0.12);
      canvas.drawCircle(Offset(sx, sy), radius, starPaint);
    }
  }

  void _drawCyberGrid(Canvas canvas, Size size) {
    final WildBiomeSpec biome = engine.biomeSpec;
    final Color gridCol = engine.isWildActive
        ? const Color(0xFFFFD600)
        : biome.gridColor;
    final Paint linePaint = Paint()
      ..color = gridCol.withValues(alpha: engine.isWildActive ? 0.18 : 0.10)
      ..strokeWidth = 1.0;

    const double step = 42.0;
    final double scrollY = (engine.elapsedTime * 22.0) % step;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = scrollY; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawWildOverdriveAura(Canvas canvas, Size size) {
    // Pulsing neon border around arena
    final double pulse = 0.5 + 0.5 * math.sin(engine.elapsedTime * 12.0);
    final Rect borderRect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 + pulse * 2.5
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFFFD600),
          Color(0xFFFF007F),
          Color(0xFF00E5FF),
          Color(0xFFFFD600),
        ],
      ).createShader(borderRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(borderRect, const Radius.circular(14)),
      borderPaint,
    );

    // Chromatic resonance rings around player
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.35 + pulse * 0.25);
    canvas.drawCircle(engine.playerPos, 46.0 + pulse * 10.0, ringPaint);

    final Paint outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFF007F).withValues(alpha: 0.28);
    canvas.drawCircle(engine.playerPos, 74.0 - pulse * 8.0, outerRing);
  }

  void _drawCrystals(Canvas canvas) {
    for (final BioCrystalEntity c in engine.crystals) {
      if (c.isMagnetized) {
        final Paint tetherPaint = Paint()
          ..color = c.color.withValues(alpha: 0.28)
          ..strokeWidth = 1.2;
        canvas.drawLine(c.position, engine.playerPos, tetherPaint);
      }

      final Path diamond = Path()
        ..moveTo(c.position.dx, c.position.dy - 7.0)
        ..lineTo(c.position.dx + 5.5, c.position.dy)
        ..lineTo(c.position.dx, c.position.dy + 7.0)
        ..lineTo(c.position.dx - 5.5, c.position.dy)
        ..close();

      final Paint glowPaint = Paint()
        ..color = c.color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(diamond, glowPaint);

      final Paint fillPaint = Paint()..color = c.color;
      canvas.drawPath(diamond, fillPaint);

      final Paint corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(c.position, 1.8, corePaint);
    }
  }

  void _drawShockwaves(Canvas canvas) {
    for (final ShockwaveRing s in engine.shockwaves) {
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.strokeWidth
        ..color = s.color.withValues(alpha: (s.alpha * 0.75).clamp(0.0, 1.0));
      canvas.drawCircle(s.center, s.radius, p);
    }
  }

  void _drawLightningArcs(Canvas canvas) {
    for (final LightningArc arc in engine.lightningArcs) {
      final Offset diff = arc.to - arc.from;
      final Offset perp = diff.distance > 1
          ? Offset(-diff.dy / diff.distance, diff.dx / diff.distance)
          : const Offset(1, 0);
      final Offset mid1 = Offset.lerp(arc.from, arc.to, 0.33)! + perp * 9.0;
      final Offset mid2 = Offset.lerp(arc.from, arc.to, 0.66)! - perp * 9.0;

      final Path path = Path()
        ..moveTo(arc.from.dx, arc.from.dy)
        ..lineTo(mid1.dx, mid1.dy)
        ..lineTo(mid2.dx, mid2.dy)
        ..lineTo(arc.to.dx, arc.to.dy);

      final Paint outer = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..color = arc.color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawPath(path, outer);

      final Paint inner = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white;
      canvas.drawPath(path, inner);
    }
  }

  void _drawProjectiles(Canvas canvas) {
    for (final ProjectileEntity p in engine.projectiles) {
      final Paint glow = Paint()
        ..color = p.color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawCircle(p.position, p.radius * 1.45, glow);

      final Paint body = Paint()..color = p.color;
      canvas.drawCircle(p.position, p.radius, body);

      final Paint core = Paint()..color = Colors.white;
      canvas.drawCircle(p.position, p.radius * 0.48, core);
    }
  }

  void _drawEnemies(Canvas canvas) {
    for (final EnemyEntity enemy in engine.enemies) {
      if (enemy.isBoss) {
        _drawBossEntity(canvas, enemy);
      } else {
        _drawStandardEnemy(canvas, enemy);
      }
    }
  }

  void _drawStandardEnemy(Canvas canvas, EnemyEntity enemy) {
    canvas.save();
    canvas.translate(enemy.position.dx, enemy.position.dy);
    canvas.rotate(enemy.heading);

    final double r = enemy.radius;
    final Paint glow = Paint()
      ..color = enemy.color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(Offset.zero, r * 1.25, glow);

    final Path hull = Path();
    switch (enemy.archetype) {
      case EnemyArchetype.swarmer:
        hull
          ..moveTo(r, 0)
          ..lineTo(-r * 0.8, -r * 0.78)
          ..lineTo(-r * 0.35, 0)
          ..lineTo(-r * 0.8, r * 0.78)
          ..close();
      case EnemyArchetype.dasher:
        hull
          ..moveTo(r * 1.2, 0)
          ..lineTo(-r * 0.4, -r * 0.9)
          ..lineTo(-r, -r * 0.35)
          ..lineTo(-r * 0.6, 0)
          ..lineTo(-r, r * 0.35)
          ..lineTo(-r * 0.4, r * 0.9)
          ..close();
      case EnemyArchetype.orbiter:
        for (int i = 0; i < 6; i++) {
          final double a = (i / 6) * math.pi * 2;
          final double px = math.cos(a) * r;
          final double py = math.sin(a) * r;
          if (i == 0) {
            hull.moveTo(px, py);
          } else {
            hull.lineTo(px, py);
          }
        }
        hull.close();
      case EnemyArchetype.splitter:
        hull
          ..moveTo(r, -r * 0.4)
          ..lineTo(r, r * 0.4)
          ..lineTo(0, r)
          ..lineTo(-r, r * 0.4)
          ..lineTo(-r, -r * 0.4)
          ..lineTo(0, -r)
          ..close();
      case EnemyArchetype.goliath:
        for (int i = 0; i < 8; i++) {
          final double a = (i / 8) * math.pi * 2 + math.pi / 8;
          final double px = math.cos(a) * r;
          final double py = math.sin(a) * r;
          if (i == 0) {
            hull.moveTo(px, py);
          } else {
            hull.lineTo(px, py);
          }
        }
        hull.close();
      case EnemyArchetype.phantom:
      case EnemyArchetype.bossLeviathan:
      case EnemyArchetype.bossHydra:
      case EnemyArchetype.bossArchitect:
        for (int i = 0; i < 8; i++) {
          final double a = (i / 8) * math.pi * 2;
          final double rad = i.isEven ? r : r * 0.48;
          final double px = math.cos(a) * rad;
          final double py = math.sin(a) * rad;
          if (i == 0) {
            hull.moveTo(px, py);
          } else {
            hull.lineTo(px, py);
          }
        }
        hull.close();
    }

    canvas.drawPath(hull, Paint()..color = enemy.color);
    canvas.drawPath(
      hull,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(Offset.zero, r * 0.30, Paint()..color = Colors.white);

    if (enemy.shieldHp > 0) {
      canvas.drawCircle(
        Offset.zero,
        r + 4.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75),
      );
    }

    canvas.restore();

    // Mini HP bar if damaged
    if (enemy.hp < enemy.maxHp) {
      final double barW = enemy.radius * 1.9;
      final Rect bgRect = Rect.fromCenter(
        center: enemy.position - Offset(0, enemy.radius + 7),
        width: barW,
        height: 3.5,
      );
      canvas.drawRect(bgRect, Paint()..color = Colors.black87);
      canvas.drawRect(
        Rect.fromLTWH(
          bgRect.left,
          bgRect.top,
          barW * enemy.hpRatio,
          bgRect.height,
        ),
        Paint()..color = enemy.color,
      );
    }
  }

  void _drawBossEntity(Canvas canvas, EnemyEntity boss) {
    canvas.save();
    canvas.translate(boss.position.dx, boss.position.dy);

    final double r = boss.radius;
    final Paint outerGlow = Paint()
      ..color = boss.color.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(Offset.zero, r * 1.38, outerGlow);

    // Rotating outer mechanical ring
    canvas.save();
    canvas.rotate(engine.elapsedTime * 1.2);
    final Path outerStar = Path();
    for (int i = 0; i < 12; i++) {
      final double a = (i / 12) * math.pi * 2;
      final double rad = i.isEven ? r * 1.12 : r * 0.78;
      final double px = math.cos(a) * rad;
      final double py = math.sin(a) * rad;
      if (i == 0) {
        outerStar.moveTo(px, py);
      } else {
        outerStar.lineTo(px, py);
      }
    }
    outerStar.close();
    canvas.drawPath(
      outerStar,
      Paint()..color = boss.color.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      outerStar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white,
    );
    canvas.restore();

    // Inner armored core
    canvas.drawCircle(
      Offset.zero,
      r * 0.55,
      Paint()..color = const Color(0xFF120824),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.34,
      Paint()..color = const Color(0xFFFFEA00),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.16,
      Paint()..color = Colors.white,
    );

    if (boss.shieldHp > 0) {
      canvas.drawCircle(
        Offset.zero,
        r * 1.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8),
      );
    }

    canvas.restore();
  }

  void _drawPlayerAndOrbitalSystems(Canvas canvas) {
    final WildHunterSpec spec = engine.hunterSpec;
    final Offset pos = engine.playerPos;

    // 1. Orbital Plasma Blades
    final List<Offset> blades = engine.getOrbitalBladePositions();
    if (blades.isNotEmpty) {
      canvas.drawCircle(
        pos,
        56.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFF007F).withValues(alpha: 0.25),
      );
      for (final Offset bPos in blades) {
        canvas.save();
        canvas.translate(bPos.dx, bPos.dy);
        canvas.rotate(engine.elapsedTime * 9.0);
        final Path saw = Path();
        for (int k = 0; k < 8; k++) {
          final double a = (k / 8) * math.pi * 2;
          final double rad = k.isEven ? 11.0 : 5.5;
          final double x = math.cos(a) * rad;
          final double y = math.sin(a) * rad;
          if (k == 0) {
            saw.moveTo(x, y);
          } else {
            saw.lineTo(x, y);
          }
        }
        saw.close();
        canvas.drawPath(
          saw,
          Paint()
            ..color = engine.isWildActive
                ? const Color(0xFFFFD600)
                : const Color(0xFFFF007F),
        );
        canvas.drawCircle(Offset.zero, 3.2, Paint()..color = Colors.white);
        canvas.restore();
      }
    }

    // 2. Twin Drone Wingmen
    if (engine.mutationStacks(MutationId.twinDroneWingmen) > 0 ||
        engine.isWildActive) {
      final Offset forward =
          Offset(math.cos(engine.playerHeading), math.sin(engine.playerHeading));
      final Offset perp = Offset(-forward.dy, forward.dx);
      for (final double side in <double>[-28.0, 28.0]) {
        final Offset dPos = pos + perp * side;
        canvas.drawCircle(
          dPos,
          6.5,
          Paint()..color = const Color(0xFF00FF9D),
        );
        canvas.drawCircle(
          dPos,
          3.0,
          Paint()..color = Colors.white,
        );
      }
    }

    // 3. Player Ship Hull
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(engine.playerHeading);

    // Thruster flame
    final double flameLen = 14.0 + (engine.isWildActive ? 10.0 : 0.0);
    final Path flame = Path()
      ..moveTo(-12, -5)
      ..lineTo(-12 - flameLen, 0)
      ..lineTo(-12, 5)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..color = engine.isWildActive
            ? const Color(0xFFFFD600)
            : const Color(0xFF00E5FF),
    );

    // Ship silhouette
    final Path shipPath = Path()
      ..moveTo(19, 0)
      ..lineTo(-11, -15)
      ..lineTo(-6, -4)
      ..lineTo(-14, 0)
      ..lineTo(-6, 4)
      ..lineTo(-11, 15)
      ..close();

    final Paint shipGlow = Paint()
      ..color = spec.primaryColor.withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);
    canvas.drawPath(shipPath, shipGlow);

    canvas.drawPath(shipPath, Paint()..color = spec.primaryColor);
    canvas.drawPath(
      shipPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white,
    );

    // Cockpit canopy
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 0), width: 10, height: 5.5),
      Paint()..color = Colors.white,
    );

    // Shield bubble
    if (engine.shield > 0) {
      canvas.drawCircle(
        Offset.zero,
        22.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = spec.secondaryColor.withValues(alpha: 0.55),
      );
    }

    canvas.restore();
  }

  void _drawParticles(Canvas canvas) {
    for (final ParticleEntity p in engine.particles) {
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: p.progress);
      canvas.drawCircle(p.position, p.radius * p.progress, paint);
    }
  }

  void _drawFloatingTexts(Canvas canvas, Size size) {
    for (final FloatingCombatText ft in engine.floatingTexts) {
      final TextSpan span = TextSpan(
        text: ft.text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: ft.color.withValues(alpha: ft.alpha),
          fontSize: ft.isBig ? 13.0 : 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: const <Shadow>[
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();
      final double dx = (ft.position.dx - tp.width / 2)
          .clamp(8.0, math.max(8.0, size.width - tp.width - 8.0));
      final double dy = ft.position.dy.clamp(12.0, size.height - 24.0);
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  void _drawTouchJoystickOverlay(Canvas canvas, Size size) {
    if (engine.joystickVector.distance < 0.05) {
      return;
    }
    final Offset base = Offset(size.width * 0.5, size.height - 54.0);
    final Offset knob = base + engine.joystickVector * 24.0;
    canvas.drawCircle(
      base,
      28.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white24,
    );
    canvas.drawCircle(
      knob,
      10.0,
      Paint()..color = engine.hunterSpec.primaryColor.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant WildArenaPainter oldDelegate) => true;
}
