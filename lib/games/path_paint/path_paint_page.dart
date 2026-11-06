import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'path_paint_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE9F5EE), surface: Colors.white, ink: Color(0xFF244B3B),
  muted: Color(0xFF729282), accent: Color(0xFF36A77B), edge: Color(0xFF244B3B),
);

Widget buildPathPaintPage(BuildContext context, GameLaunch launch) =>
    PathPaintPage(launch: launch);

class PathPaintPage extends StatefulWidget {
  const PathPaintPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<PathPaintPage> createState() => _PathPaintPageState();
}

class _PathPaintPageState extends State<PathPaintPage> with LevelFlow<PathPaintPage> {
  late PathPaintEngine _engine;
  bool _drawing = false;
  bool _blocked = false;
  Offset? _lastPoint;
  final List<int> _trail = [];
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = PathPaintEngine.forLevel(level);
    _trail
      ..clear()
      ..add(_engine.start);
    _drawing = false;
    _blocked = false;
    _lastPoint = null;
  }

  int? _cellAt(Offset local, double side) {
    final cellSize = side / _engine.size;
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || col < 0 || row >= _engine.size || col >= _engine.size) return null;
    return row * _engine.size + col;
  }

  void _move(int? cell) {
    if (!_drawing || cell == null || reported) return;
    final result = _engine.moveTo(cell);
    if (result == PaintMove.ignored) return;
    setState(() {
      _blocked = result == PaintMove.blocked;
      if (result == PaintMove.moved || result == PaintMove.completed) {
        _trail.add(_engine.position);
      }
    });
    if (result == PaintMove.blocked) {
      HapticFeedback.selectionClick();
    } else if (result == PaintMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: {'focus': _engine.focusMetric});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _trace(Offset point, double boardSide) {
    final previous = _lastPoint;
    _lastPoint = point;
    if (previous == null) return;
    final cellSize = boardSide / _engine.size;
    final samples = math.max(1, (point - previous).distance / (cellSize * .35)).ceil();
    for (var i = 1; i <= samples; i++) {
      final t = i / samples;
      final sample = Offset(previous.dx + (point.dx - previous.dx) * t,
          previous.dy + (point.dy - previous.dy) * t);
      _move(_cellAt(sample, boardSide));
      if (reported) break;
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Path Paint', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = (box.maxWidth - 36).clamp(260.0, 440.0).toDouble();
      final available = box.maxHeight - (reported ? 270 : 160);
      final boardSide = math.min(side, math.max(190.0, available));
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(reported ? 'PATH COMPLETE' : 'TRACE FROM START TO EXIT',
          style: TextStyle(color: _palette.muted, fontWeight: FontWeight.w900,
            fontSize: 11, letterSpacing: 1.4)),
        const SizedBox(height: 10),
        SizedBox(width: boardSide, height: boardSide,
          child: GestureDetector(
            onPanStart: (d) {
              final cell = _cellAt(d.localPosition, boardSide);
              if (cell == _engine.start) {
                setState(() { _drawing = true; _lastPoint = d.localPosition; });
              }
              _move(cell);
            },
            onPanUpdate: (d) => _trace(d.localPosition, boardSide),
            onPanEnd: (_) => setState(() { _drawing = false; _lastPoint = null; }),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _blocked ? const Color(0xFFE66B65) : _palette.edge,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_blocked ? const Color(0xFFE66B65)
                        : _palette.accent).withValues(alpha: .24),
                    blurRadius: 11,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _MazePainter(
                  _engine,
                  trail: _trail,
                  blocked: _blocked,
                  drawing: _drawing,
                ),
              ),
            ),
          )),
        const SizedBox(height: 14),
        Text(reported ? 'Nice route!' : _blocked ? 'That wall is closed.' : 'Press and keep holding. Paint the path.',
          textAlign: TextAlign.center, style: TextStyle(color: _palette.ink,
            fontSize: 14, fontWeight: FontWeight.w800)),
        if (reported) ...[
          const SizedBox(height: 14),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: LevelResultPanel(palette: _palette, launch: launch, level: level,
              stars: _engine.blockedMoves == 0 ? 3 : _engine.blockedMoves < 4 ? 2 : 1,
              detail: 'A clear line from start to exit.', onReplay: replayLevel, onNext: nextLevel)),
        ],
      ]));
    }),
  );
}

class _MazePainter extends CustomPainter {
  const _MazePainter(this.engine, {
    required this.trail,
    required this.blocked,
    required this.drawing,
  });

  final PathPaintEngine engine;
  final List<int> trail;
  final bool blocked, drawing;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / engine.size;
    final board = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(16)),
      Paint()..color = const Color(0xFFF3FBF5),
    );

    final visited = Paint()..color = const Color(0xFFC3EFD1);
    final tileShine = Paint()
      ..color = Colors.white.withValues(alpha: .48);
    for (final i in engine.paintedCells) {
      final rect = Rect.fromLTWH(
        (i % engine.size) * cell + 2,
        (i ~/ engine.size) * cell + 2,
        cell - 4, cell - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        visited,
      );
      canvas.drawLine(
        rect.topLeft + const Offset(4, 3),
        rect.topRight + const Offset(-4, 3),
        tileShine..strokeWidth = 1.5,
      );
    }

    Offset center(int i) => Offset(
      (i % engine.size + .5) * cell,
      (i ~/ engine.size + .5) * cell,
    );

    if (trail.isNotEmpty) {
      final path = Path()..moveTo(center(trail.first).dx, center(trail.first).dy);
      for (final index in trail.skip(1)) {
        final position = center(index);
        path.lineTo(position.dx, position.dy);
      }
      final outline = Paint()
        ..color = const Color(0x779FE4C1)
        ..strokeWidth = cell * .48
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final inner = Paint()
        ..color = const Color(0xFF58BF91)
        ..strokeWidth = cell * .22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, outline);
      canvas.drawPath(path, inner);
    }

    final walls = Paint()
      ..color = const Color(0xFF376552)
      ..strokeWidth = math.max(2.0, cell * .075)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < engine.size * engine.size; i++) {
      final x = (i % engine.size) * cell;
      final y = (i ~/ engine.size) * cell;
      final mask = engine.walls[i];
      if (mask & 1 != 0) {
        canvas.drawLine(Offset(x, y), Offset(x + cell, y), walls);
      }
      if (mask & 8 != 0) {
        canvas.drawLine(Offset(x, y), Offset(x, y + cell), walls);
      }
      if (mask & 2 != 0) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), walls);
      }
      if (mask & 4 != 0) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), walls);
      }
    }

    final start = center(engine.start);
    final goal = center(engine.goal);
    canvas.drawCircle(start, cell * .25,
        Paint()..color = const Color(0xFF2DA979));
    canvas.drawCircle(start, cell * .12, Paint()..color = Colors.white);
    canvas.drawCircle(goal, cell * .29,
        Paint()..color = const Color(0xFFFFE2A3));
    canvas.drawCircle(goal, cell * .19,
        Paint()..color = const Color(0xFFFFA45B));
    canvas.drawCircle(goal, cell * .075,
        Paint()..color = Colors.white);
    final current = center(engine.position);
    canvas.drawCircle(current, cell * .21,
      Paint()..color = (blocked
          ? const Color(0xFFE66B65) : const Color(0xFF36A77B))
          .withValues(alpha: .22));
    canvas.drawCircle(current, cell * .15,
        Paint()..color = Colors.white);
    canvas.drawCircle(
      current,
      cell * .15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = blocked
            ? const Color(0xFFE66B65) : const Color(0xFF36A77B),
    );
  }

  @override
  bool shouldRepaint(covariant _MazePainter old) => true;
}
