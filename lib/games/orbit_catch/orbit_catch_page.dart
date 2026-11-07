import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'orbit_catch_engine.dart';

const _palette = GamePalette(ground: Color(0xFFEEF4FF), surface: Colors.white, ink: Color(0xFF455879),
  muted: Color(0xFF8191AF), accent: Color(0xFF6389D4), edge: Color(0xFF455879));
Widget buildOrbitCatchPage(BuildContext context, GameLaunch launch) => OrbitCatchPage(launch: launch);

class OrbitCatchPage extends StatefulWidget {
  const OrbitCatchPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<OrbitCatchPage> createState() => _OrbitCatchPageState();
}

class _OrbitCatchPageState extends State<OrbitCatchPage> with LevelFlow<OrbitCatchPage> {
  late OrbitCatchEngine _engine;
  int _fromLane = 0;
  int _fromSector = 0;
  int _hazardPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = OrbitCatchEngine.forLevel(level);
    _fromLane = _engine.lane;
    _fromSector = _engine.sector;
    _hazardPulse = 0;
  }

  void _act(OrbitAction action) {
    final previousLane = _engine.lane;
    final previousSector = _engine.sector;
    final result = _engine.act(action);
    if (result == OrbitMove.ignored) return;
    setState(() {
      _fromLane = previousLane;
      _fromSector = previousSector;
      if (result == OrbitMove.hitHazard) _hazardPulse++;
    });
    if (result == OrbitMove.hitHazard) {
      HapticFeedback.heavyImpact();
    } else if (result == OrbitMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Orbit Catch', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final motion = reduceMotion ? Duration.zero
          : const Duration(milliseconds: 235);
      final side = math.min(box.maxWidth - 36, box.maxHeight - (reported || _engine.isFailed ? 350 : 280)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'STARS', value: '${_engine.collected.length}/${_engine.stars.length}', palette: _palette),
          StatChip(label: 'MOVES', value: _engine.moves.toString(), palette: _palette),
        ])),
        const SizedBox(height: 9),
        Semantics(
          label: 'Orbit ${_engine.lane + 1} of 2, '
              'sector ${_engine.sector + 1}, '
              '${_engine.collected.length} of ${_engine.stars.length} stars',
          child: Shake(
            trigger: _hazardPulse,
            child: SizedBox(
              width: side, height: side,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('orbit-step-${_engine.moves}'),
                tween: Tween(begin: 0, end: 1),
                duration: motion,
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => CustomPaint(
                  key: const ValueKey('orbit-board'),
                  painter: _OrbitPainter(
                    _engine,
                    progress: progress,
                    fromLane: _fromLane,
                    fromSector: _fromSector,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ChunkyIconButton(icon: Icons.rotate_left_rounded, tooltip: 'Counter clockwise', palette: _palette,
            onPressed: reported || _engine.isFailed ? null : () => _act(OrbitAction.counterClockwise)),
          const SizedBox(width: 9),
          SizedBox(width: 130, height: 48, child: ChunkyButton(onPressed: reported || _engine.isFailed ? null : () => _act(OrbitAction.switchLane),
            color: _palette.accent, edgeColor: _palette.edge, depth: 3, radius: 12,
            child: const Text('SWITCH ORBIT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)))),
          const SizedBox(width: 9),
          ChunkyIconButton(icon: Icons.rotate_right_rounded, tooltip: 'Clockwise', palette: _palette,
            onPressed: reported || _engine.isFailed ? null : () => _act(OrbitAction.clockwise)),
        ]),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= _engine.stars.length * 3 ? 3 : 2, detail: 'Collected every star in orbit.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(8), child: RetryPanel(palette: _palette,
          title: 'METEOR IMPACT', detail: 'Switch to the other orbit to avoid hazards.', onRetry: replayLevel))
        else const HintLine('DODGE RED METEORS · COLLECT GOLD STARS', palette: _palette),
      ]));
    }));
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.engine, {
    required this.progress,
    required this.fromLane,
    required this.fromSector,
  });

  final OrbitCatchEngine engine;
  final double progress;
  final int fromLane;
  final int fromSector;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .38;
    final outer = Paint()
      ..color = const Color(0xFFACBFDF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final inner = Paint()
      ..color = const Color(0xFFD1DCF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, outer);
    canvas.drawCircle(center, radius * .66, inner);
    canvas.drawCircle(
      center, radius * .27,
      Paint()..color = const Color(0xFFE0EAFE),
    );
    canvas.drawCircle(
      center, radius * .16,
      Paint()..color = const Color(0xFFB7CCED),
    );

    Offset orbitPoint(double lane, double sector) {
      final distance = radius * (.66 + .34 * lane);
      final angle = -math.pi / 2 + sector * math.pi * 2 /
          OrbitCatchEngine.sectors;
      return center + Offset(math.cos(angle) * distance,
          math.sin(angle) * distance);
    }

    for (var lane = 0; lane < 2; lane++) {
      for (var sector = 0; sector < OrbitCatchEngine.sectors; sector++) {
        final point = orbitPoint(lane.toDouble(), sector.toDouble());
        final key = engine.key(lane, sector);
        if (engine.stars.contains(key) &&
            !engine.collected.contains(key)) {
          // A star silhouette reads clearly even without a yellow fill.
          final path = Path();
          for (var corner = 0; corner < 10; corner++) {
            final angle = -math.pi / 2 + corner * math.pi / 5;
            final r = corner.isEven ? 11.0 : 5.0;
            final vertex = point + Offset(math.cos(angle) * r,
                math.sin(angle) * r);
            if (corner == 0) {
              path.moveTo(vertex.dx, vertex.dy);
            } else {
              path.lineTo(vertex.dx, vertex.dy);
            }
          }
          path.close();
          canvas.drawPath(
            path, Paint()..color = const Color(0xFFFFC85D));
          canvas.drawCircle(point, 2.5,
            Paint()..color = Colors.white);
        } else if (engine.hazards.contains(key)) {
          final diamond = Path()
            ..moveTo(point.dx, point.dy - 11)
            ..lineTo(point.dx + 9, point.dy)
            ..lineTo(point.dx, point.dy + 11)
            ..lineTo(point.dx - 9, point.dy)
            ..close();
          canvas.drawPath(diamond,
            Paint()..color = const Color(0xFFE86C78));
          canvas.drawCircle(point, 2.5,
            Paint()..color = const Color(0xFFFFE3E2));
        }
      }
    }

    // Take the shortest arc when wrapping from sector 12 back to 1.
    final currentAngle = engine.sector.toDouble();
    var arc = currentAngle - fromSector;
    if (arc > OrbitCatchEngine.sectors / 2) {
      arc -= OrbitCatchEngine.sectors;
    } else if (arc < -OrbitCatchEngine.sectors / 2) {
      arc += OrbitCatchEngine.sectors;
    }
    final animatedSector = fromSector + arc * progress;
    final animatedLane = fromLane +
        (engine.lane - fromLane) * progress;
    final player = orbitPoint(animatedLane, animatedSector);
    final halo = Rect.fromCircle(center: player, radius: 19);
    canvas.drawCircle(player, 19, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x666389D4), Color(0x006389D4)],
      ).createShader(halo));
    canvas.drawCircle(player, 12,
      Paint()..color = const Color(0xFF4E77C7));
    canvas.drawCircle(player + const Offset(-3, -3), 4,
      Paint()..color = Colors.white);
    canvas.drawCircle(center, 5,
      Paint()..color = const Color(0xFF7186A9));
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fromLane != fromLane ||
      oldDelegate.fromSector != fromSector ||
      oldDelegate.engine != engine;
}
