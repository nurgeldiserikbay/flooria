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
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = OrbitCatchEngine.forLevel(level);
  void _act(OrbitAction action) {
    final result = _engine.act(action); setState(() {});
    if (result == OrbitMove.hitHazard) HapticFeedback.heavyImpact(); else HapticFeedback.selectionClick();
    if (result == OrbitMove.completed) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Orbit Catch', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 36, box.maxHeight - (reported || _engine.isFailed ? 350 : 280)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'STARS', value: '${_engine.collected.length}/${_engine.stars.length}', palette: _palette),
          StatChip(label: 'MOVES', value: _engine.moves.toString(), palette: _palette),
        ])),
        const SizedBox(height: 9),
        SizedBox(width: side, height: side, child: CustomPaint(painter: _OrbitPainter(_engine))),
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
  const _OrbitPainter(this.engine);
  final OrbitCatchEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .38;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFCBD7EE)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(center, radius * .66, Paint()..color = const Color(0xFFCBD7EE)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(center, radius * .33, Paint()..color = const Color(0xFFDEE6F5));
    for (var lane = 0; lane < 2; lane++) {
      for (var sector = 0; sector < OrbitCatchEngine.sectors; sector++) {
        final angle = -math.pi / 2 + sector * math.pi * 2 / OrbitCatchEngine.sectors;
        final r = lane == 0 ? radius * .66 : radius;
        final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        final key = engine.key(lane, sector);
        if (engine.stars.contains(key) && !engine.collected.contains(key)) {
          canvas.drawCircle(point, 9, Paint()..color = const Color(0xFFF2BE4D));
          canvas.drawCircle(point, 4, Paint()..color = Colors.white);
        } else if (engine.hazards.contains(key)) {
          canvas.drawCircle(point, 8, Paint()..color = const Color(0xFFE56C6C));
        }
      }
    }
    final angle = -math.pi / 2 + engine.sector * math.pi * 2 / OrbitCatchEngine.sectors;
    final r = engine.lane == 0 ? radius * .66 : radius;
    final player = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    canvas.drawCircle(player, 13, Paint()..color = const Color(0xFF6389D4));
    canvas.drawCircle(player, 5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFF657B9D));
  }
  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => true;
}
