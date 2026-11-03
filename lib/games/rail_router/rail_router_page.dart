import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'rail_router_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF4F0), surface: Colors.white, ink: Color(0xFF3F5B55),
  muted: Color(0xFF7E9990), accent: Color(0xFF5AAE92), edge: Color(0xFF3F5B55),
);
const _trainColors = [Color(0xFF579DD0), Color(0xFFE58A62)];

Widget buildRailRouterPage(BuildContext context, GameLaunch launch) =>
    RailRouterPage(launch: launch);

class RailRouterPage extends StatefulWidget {
  const RailRouterPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<RailRouterPage> createState() => _RailRouterPageState();
}

class _RailRouterPageState extends State<RailRouterPage> with LevelFlow<RailRouterPage> {
  late RailRouterEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = RailRouterEngine.forLevel(level);

  void _switch(int train) {
    if (_engine.toggle(train) == RailAction.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  void _advance() {
    final result = _engine.advance();
    setState(() {});
    if (result == RailAction.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == RailAction.collision) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Rail Router', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth - 36,
        constraints.maxHeight - (reported || _engine.isFailed ? 280 : 225))
        .clamp(240.0, 360.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'TICK', value: '${_engine.time}', palette: _palette),
              StatChip(label: 'TRAINS', value: '${_engine.passed.where((x) => x).length}/2', palette: _palette),
            ])),
          const SizedBox(height: 12),
          Container(width: size, height: size, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD8E8E1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: CustomPaint(painter: _RailPainter(_engine)),
          ),
          const SizedBox(height: 12),
          for (var train = 0; train < 2; train++)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
              child: ChunkyButton(
                onPressed: reported || _engine.isFailed ? null : () => _switch(train),
                color: _engine.diverted[train] ? _trainColors[train] : Colors.white,
                edgeColor: _engine.diverted[train] ? GamePalette.shade(_trainColors[train]) : _palette.edge,
                depth: 3, radius: 12, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(children: [
                  Icon(Icons.train_rounded, color: _engine.diverted[train] ? Colors.white : _trainColors[train]),
                  const SizedBox(width: 8),
                  Expanded(child: Text('TRAIN ${train + 1} · ${_engine.diverted[train] ? 'BYPASS' : 'CROSSING'}',
                    style: TextStyle(color: _engine.diverted[train] ? Colors.white : _palette.ink,
                      fontWeight: FontWeight.w900))),
                  Text('${_engine.countdowns[train]} TICKS',
                    style: TextStyle(color: _engine.diverted[train] ? Colors.white : _palette.muted,
                      fontSize: 11, fontWeight: FontWeight.w900)),
                ]),
              )),
          const SizedBox(height: 7),
          if (!reported && !_engine.isFailed)
            SizedBox(width: 220, height: 48,
              child: ChunkyButton(onPressed: _advance, color: _palette.accent,
                edgeColor: _palette.edge, depth: 4, radius: 14,
                child: const Text('ADVANCE TRAINS', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)))),
          const SizedBox(height: 4),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.diverted.where((x) => x).length == 1 ? 3 : 2,
                detail: 'Both trains passed without a collision.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'COLLISION',
                detail: 'Switch one train onto the bypass.', onRetry: replayLevel))
          else
            const HintLine('SWITCH ONE ROUTE BEFORE THE TRAINS MEET', palette: _palette),
        ]));
    }),
  );
}

class _RailPainter extends CustomPainter {
  const _RailPainter(this.engine);
  final RailRouterEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rail = Paint()..color = const Color(0xFF73857F)..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final inner = Paint()..color = const Color(0xFFEAF1ED)..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), rail);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), rail);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), inner);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), inner);
    final bypass = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(center.dx + size.width * .28, center.dy - size.height * .36,
        center.dx + size.width * .28, center.dy + size.height * .36,
        center.dx, center.dy);
    canvas.drawPath(bypass, Paint()..color = const Color(0xFF5AAE92)
      ..style = PaintingStyle.stroke..strokeWidth = 7);
    canvas.drawCircle(center, 19, Paint()..color = const Color(0xFFFFD879));
    for (var train = 0; train < 2; train++) {
      final progress = (engine.time / engine.arrivals[train]).clamp(0.0, 1.0).toDouble();
      Offset point;
      if (!engine.diverted[train]) {
        point = train == 0
          ? Offset(size.width * progress, center.dy)
          : Offset(center.dx, size.height * progress);
      } else if (train == 0) {
        point = Offset(size.width * progress, center.dy - sin(progress * pi) * size.height * .28);
      } else {
        point = Offset(center.dx + sin(progress * pi) * size.width * .28, size.height * progress);
      }
      canvas.drawCircle(point, 13, Paint()..color = _trainColors[train]);
      canvas.drawCircle(point, 13, Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }
  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) => true;
}
