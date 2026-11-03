import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'rope_untangle_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF4EEF7), surface: Colors.white, ink: Color(0xFF51465C),
  muted: Color(0xFF8B7F98), accent: Color(0xFF9A70C5), edge: Color(0xFF51465C),
);

Widget buildRopeUntanglePage(BuildContext context, GameLaunch launch) =>
    RopeUntanglePage(launch: launch);

class RopeUntanglePage extends StatefulWidget {
  const RopeUntanglePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<RopeUntanglePage> createState() => _RopeUntanglePageState();
}

class _RopeUntanglePageState extends State<RopeUntanglePage>
    with LevelFlow<RopeUntanglePage> {
  late RopeUntangleEngine _engine;
  int? _dragged;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() { _engine = RopeUntangleEngine.forLevel(level); _dragged = null; }

  void _move(Offset local, Size size) {
    final node = _dragged;
    if (node == null) return;
    final result = _engine.moveNode(node,
      Point<double>(local.dx / size.width, local.dy / size.height));
    if (result == RopeMove.ignored) return;
    setState(() {});
    if (result == RopeMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Rope Untangle',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported ? 225 : 155)).clamp(270.0, 430.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'CROSSES', value: '${_engine.crossingCount}', palette: _palette),
                StatChip(label: 'JOINTS', value: '${_engine.positions.length}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          GestureDetector(
            onPanStart: (details) {
              if (reported) return;
              final point = details.localPosition;
              var closest = double.infinity;
              int? selected;
              for (var index = 0; index < _engine.positions.length; index++) {
                final node = _engine.positions[index];
                final dx = point.dx - node.x * side;
                final dy = point.dy - node.y * side;
                final distance = sqrt(dx * dx + dy * dy);
                if (distance < closest) { closest = distance; selected = index; }
              }
              _dragged = closest <= side * .11 ? selected : null;
            },
            onPanUpdate: (details) => _move(details.localPosition, Size.square(side)),
            onPanEnd: (_) => _dragged = null,
            child: Container(width: side, height: side,
              decoration: BoxDecoration(color: const Color(0xFFEEE8F1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _palette.edge, width: 2),
                boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
              child: CustomPaint(painter: _RopePainter(_engine)),
            ),
          ),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 4 + level ~/ 4 ? 3 : 2,
                detail: 'Every rope is clear and every joint is apart.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('DRAG THE JOINTS UNTIL THE ROPES DO NOT CROSS', palette: _palette),
        ]));
    }),
  );
}

class _RopePainter extends CustomPainter {
  const _RopePainter(this.engine);
  final RopeUntangleEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    final crossed = engine.crossingCount > 0;
    final line = Paint()
      ..color = crossed ? const Color(0xFFE38A7D) : const Color(0xFF71B486)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in engine.edges) {
      final first = engine.positions[a], second = engine.positions[b];
      canvas.drawLine(Offset(first.x * size.width, first.y * size.height),
        Offset(second.x * size.width, second.y * size.height), line);
    }
    final nodePaint = Paint()..color = const Color(0xFF9A70C5);
    final border = Paint()..color = _palette.ink..style = PaintingStyle.stroke..strokeWidth = 2;
    for (var i = 0; i < engine.positions.length; i++) {
      final point = engine.positions[i];
      final center = Offset(point.x * size.width, point.y * size.height);
      canvas.drawCircle(center, size.width * .042, nodePaint);
      canvas.drawCircle(center, size.width * .042, border);
      final text = TextPainter(text: TextSpan(text: '${i + 1}', style: TextStyle(
        color: Colors.white, fontSize: size.width * .031, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }
  @override
  bool shouldRepaint(covariant _RopePainter oldDelegate) => true;
}
