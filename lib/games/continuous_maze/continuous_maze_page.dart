import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import 'continuous_maze_engine.dart';

const _ink = Color(0xFF263866);
const _muted = Color(0xFF7B88A6);
const _mint = Color(0xFF54B99B);
const _paper = Color(0xFFF4F7FF);

Widget buildContinuousMazePage(BuildContext context, GameLaunch launch) =>
    ContinuousMazePage(launch: launch);

class ContinuousMazePage extends StatefulWidget {
  const ContinuousMazePage({super.key, required this.launch});

  final GameLaunch launch;

  @override
  State<ContinuousMazePage> createState() => _ContinuousMazePageState();
}

class _ContinuousMazePageState extends State<ContinuousMazePage> {
  late ContinuousMazeEngine _engine;
  late int _level;
  bool _drawing = false;
  int _revision = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _level = widget.launch.level.clamp(1, widget.launch.maxLevel).toInt();
    _engine = ContinuousMazeEngine.forLevel(_level);
  }

  MazeCell _cellAt(Offset point, Size size) {
    final row = (point.dy / size.height * _engine.side)
        .floor()
        .clamp(0, _engine.side - 1)
        .toInt();
    final column = (point.dx / size.width * _engine.side)
        .floor()
        .clamp(0, _engine.side - 1)
        .toInt();
    return MazeCell(row, column);
  }

  void _startTrace(DragStartDetails details, Size size) {
    if (_engine.complete) return;
    final result = _engine.begin(_cellAt(details.localPosition, size));
    setState(() {
      _drawing = result == MazeMoveResult.started;
      _message = _drawing ? null : 'Start at the green entrance.';
      _revision++;
    });
    if (!_drawing) HapticFeedback.selectionClick();
  }

  void _updateTrace(DragUpdateDetails details, Size size) {
    if (!_drawing || _engine.complete) return;
    final target = _cellAt(details.localPosition, size);
    final current = _engine.path.last;
    final rowDelta = target.row - current.row;
    final columnDelta = target.column - current.column;
    if (rowDelta == 0 && columnDelta == 0) return;
    if (rowDelta != 0 && columnDelta != 0) {
      setState(() {
        _message = 'Follow one corridor at a time.';
        _revision++;
      });
      return;
    }

    final distance = rowDelta.abs() + columnDelta.abs();
    final rowStep = rowDelta == 0 ? 0 : rowDelta ~/ rowDelta.abs();
    final columnStep = columnDelta == 0 ? 0 : columnDelta ~/ columnDelta.abs();
    var latest = MazeMoveResult.ignored;
    for (var step = 1; step <= distance; step++) {
      latest = _engine.moveTo(MazeCell(
        current.row + rowStep * step,
        current.column + columnStep * step,
      ));
      if (latest == MazeMoveResult.invalid ||
          latest == MazeMoveResult.completed) {
        break;
      }
    }
    setState(() {
      _message = latest == MazeMoveResult.invalid
          ? 'That wall is closed. Trace along a corridor.'
          : latest == MazeMoveResult.backtracked
              ? 'Back at the previous step.'
              : null;
      _revision++;
    });
    if (latest == MazeMoveResult.invalid) {
      HapticFeedback.selectionClick();
    } else if (latest == MazeMoveResult.completed) {
      HapticFeedback.lightImpact();
      widget.launch.onComplete(GameResult(
        level: _level,
        score: _engine.score,
        metrics: {'planning': math.max(0, 100 - _engine.invalidMoves * 8)},
      ));
    }
  }

  void _endTrace(DragEndDetails details) {
    if (!_drawing) return;
    _drawing = false;
    if (!_engine.complete && _engine.path.isNotEmpty) {
      _engine.cancelTrace();
      setState(() {
        _message = 'Keep your finger down until you reach the exit.';
        _revision++;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _nextLevel() {
    if (_level >= widget.launch.maxLevel) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _level++;
      _engine = ContinuousMazeEngine.forLevel(_level);
      _drawing = false;
      _message = null;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        titleSpacing: 4,
        title: Text('One Stroke  ·  $_level',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _LevelPill(level: _level)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
            child: Column(
              children: [
                Text(
                  _engine.complete ? 'MAZE COMPLETE' : 'TRACE THE MAZE',
                  key: const ValueKey('continuous-maze-status'),
                  style: TextStyle(
                    color: _engine.complete ? _mint : _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _engine.complete
                      ? 'You reached the exit in one stroke.'
                      : _message ?? 'Start at green. Keep one finger down to the star.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _engine.path.length / _engine.solution.length,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE3E9F5),
                        color: _engine.complete ? _mint : const Color(0xFF8A82D8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${_engine.invalidMoves} misses',
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(builder: (context, boardBounds) {
                    final side = math.min(
                      boardBounds.maxWidth,
                      boardBounds.maxHeight,
                    ).toDouble();
                    final size = Size.square(side);
                    return Center(
                      child: SizedBox.fromSize(
                        key: const ValueKey('continuous-maze-board'),
                        size: size,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) => _startTrace(details, size),
                          onPanUpdate: (details) => _updateTrace(details, size),
                          onPanEnd: _endTrace,
                          child: CustomPaint(
                            painter: _MazePainter(
                              engine: _engine,
                              revision: _revision,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Text(
                      '${_engine.moves} steps  ·  ${_engine.side} × ${_engine.side}',
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (!_engine.complete)
                    TextButton.icon(
                      onPressed: _engine.path.isEmpty
                          ? null
                          : () => setState(() {
                                _engine.reset();
                                _drawing = false;
                                _message = null;
                                _revision++;
                              }),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('RESTART'),
                    ),
                ]),
                if (_engine.complete)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _nextLevel,
                      style: FilledButton.styleFrom(
                        backgroundColor: _mint,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17)),
                      ),
                      child: Text(
                        _level >= widget.launch.maxLevel ? 'FINISH' : 'NEXT LEVEL',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _mint.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('LV $level',
            style: const TextStyle(
                color: _mint, fontSize: 11, fontWeight: FontWeight.w900)),
      );
}

class _MazePainter extends CustomPainter {
  const _MazePainter({required this.engine, required this.revision});

  final ContinuousMazeEngine engine;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    final side = engine.side;
    final cell = size.width / side;
    final board = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * .25),
    );
    canvas.drawRRect(board, Paint()..color = const Color(0xFFE4E8FA));

    final wallPaint = Paint()
      ..color = const Color(0xFF777EB2)
      ..strokeWidth = math.max(2.4, cell * .075).toDouble()
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < side; row++) {
      for (var column = 0; column < side; column++) {
        final current = MazeCell(row, column);
        final left = column * cell;
        final top = row * cell;
        if (row == 0 || !engine.isPassage(current, MazeCell(row - 1, column))) {
          canvas.drawLine(Offset(left, top), Offset(left + cell, top), wallPaint);
        }
        if (column == 0 || !engine.isPassage(current, MazeCell(row, column - 1))) {
          canvas.drawLine(Offset(left, top), Offset(left, top + cell), wallPaint);
        }
        if (row == side - 1) {
          canvas.drawLine(Offset(left, top + cell),
              Offset(left + cell, top + cell), wallPaint);
        }
        if (column == side - 1) {
          canvas.drawLine(Offset(left + cell, top),
              Offset(left + cell, top + cell), wallPaint);
        }
      }
    }

    Offset center(MazeCell point) => Offset(
          (point.column + .5) * cell,
          (point.row + .5) * cell,
        );
    if (engine.path.isNotEmpty) {
      final tracePaint = Paint()
        ..color = _mint
        ..strokeWidth = cell * .26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final trace = Path()..moveTo(center(engine.path.first).dx,
          center(engine.path.first).dy);
      for (final point in engine.path.skip(1)) {
        final position = center(point);
        trace.lineTo(position.dx, position.dy);
      }
      canvas.drawPath(trace, tracePaint);
    }

    _marker(canvas, center(engine.start), cell * .28,
        const Color(0xFF71D5A9), 'S', const Color(0xFF194E46));
    _marker(canvas, center(engine.goal), cell * .29,
        const Color(0xFFFFD36E), '★', const Color(0xFF80591B));
    if (engine.path.isNotEmpty && !engine.complete) {
      canvas.drawCircle(center(engine.path.last), cell * .15,
          Paint()..color = Colors.white);
      canvas.drawCircle(center(engine.path.last), cell * .095,
          Paint()..color = const Color(0xFF258D77));
    }
  }

  void _marker(Canvas canvas, Offset center, double radius, Color color,
      String label, Color labelColor) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: radius * (label == '★' ? 1.18 : 1.0),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas,
        center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) =>
      oldDelegate.engine != engine || oldDelegate.revision != revision;
}
