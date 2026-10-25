import 'dart:math';

import 'package:flutter/material.dart';

import 'loop_logic_engine.dart';

class LoopLogicPage extends StatefulWidget {
  const LoopLogicPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves) onSessionEnd;

  @override
  State<LoopLogicPage> createState() => _LoopLogicPageState();
}

class _LoopLogicPageState extends State<LoopLogicPage> {
  late LoopLogicSession session;
  int revision = 0;
  int paintVersion = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 1543
        : widget.floor! * 1877 + revision;
    session = LoopLogicSession(seed: seed);
    reported = false;
  }

  void _toggle(LoopEdge edge) {
    if (!session.toggle(edge)) return;
    setState(() => paintVersion++);
  }

  void _advance() {
    if (!session.advance()) return;
    setState(() => paintVersion++);
    if (!session.complete || reported) return;
    reported = true;
    widget.onSessionEnd(LoopLogicSession.totalRounds, session.totalMoves);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.complete;
    final puzzle = session.puzzle;
    final solved = session.roundComplete || complete;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FC),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Loop Logic',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF4FAFF),
        foregroundColor: const Color(0xFF426287),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'LEVEL ${widget.floor}',
                  style: const TextStyle(
                    color: Color(0xFF7892A9),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          color: Color(0xFF71AFC0), size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complete
                              ? 'Three loops complete!'
                              : session.roundComplete
                                  ? 'Loop closed!'
                                  : 'Connect the numbers with one loop',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF426287),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${complete ? LoopLogicSession.totalRounds : session.round + 1} / ${LoopLogicSession.totalRounds}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6888A5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final side = min(
                          420.0,
                          min(bounds.maxWidth, bounds.maxHeight),
                        );
                        return Center(
                          child: SizedBox.square(
                            dimension: side,
                            child: _LoopBoard(
                              puzzle: puzzle,
                              version: paintVersion,
                              enabled: !complete && !session.roundComplete,
                              solved: solved,
                              onToggle: _toggle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    solved
                        ? 'Every clue fits one continuous loop.'
                        : 'Tap the short edges to draw or erase your loop.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7892A9),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${session.totalMoves} edge changes',
                          style: const TextStyle(
                            color: Color(0xFF7892A9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: complete
                            ? () => setState(() {
                                  revision++;
                                  paintVersion++;
                                  _restart();
                                })
                            : session.roundComplete
                                ? _advance
                                : () => setState(() {
                                      revision++;
                                      paintVersion++;
                                      _restart();
                                    }),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD991),
                          foregroundColor: const Color(0xFF5E6458),
                        ),
                        icon: Icon(
                          complete || !session.roundComplete
                              ? Icons.refresh_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          complete
                              ? 'PLAY AGAIN'
                              : session.roundComplete
                                  ? 'NEXT LOOP'
                                  : 'RESTART',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoopBoard extends StatelessWidget {
  const _LoopBoard({
    required this.puzzle,
    required this.version,
    required this.enabled,
    required this.solved,
    required this.onToggle,
  });

  final LoopLogicPuzzle puzzle;
  final int version;
  final bool enabled;
  final bool solved;
  final ValueChanged<LoopEdge> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final cell = min(bounds.maxWidth, bounds.maxHeight) /
            LoopLogicPuzzle.size;
        final hit = max(20.0, cell * .28);
        final side = cell * LoopLogicPuzzle.size;
        return SizedBox.square(
          dimension: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const ValueKey<String>('loop-board-painter'),
                  painter: _LoopPainter(
                    puzzle: puzzle,
                    version: version,
                    solved: solved,
                  ),
                ),
              ),
              for (final edge in LoopLogicPuzzle.allEdges)
                _edgeTarget(edge, cell, hit),
            ],
          ),
        );
      },
    );
  }

  Widget _edgeTarget(LoopEdge edge, double cell, double hit) {
    final vertexCount = LoopLogicPuzzle.vertexCount;
    final row = edge.first ~/ vertexCount;
    final column = edge.horizontal
        ? edge.first % vertexCount
        : edge.first % vertexCount;
    final horizontal = edge.horizontal;
    final boardSide = cell * LoopLogicPuzzle.size;
    final left = horizontal
        ? column * cell + hit / 2
        : column == 0
            ? 0.0
            : column == LoopLogicPuzzle.size
                ? boardSide - hit
                : column * cell - hit / 2;
    final top = horizontal
        ? row == 0
            ? 0.0
            : row == LoopLogicPuzzle.size
                ? boardSide - hit
                : row * cell - hit / 2
        : row * cell + hit / 2;
    final width = horizontal ? cell - hit : hit;
    final height = horizontal ? hit : cell - hit;
    final selected = puzzle.selectedEdges.contains(edge);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: enabled,
        label:
            '${horizontal ? 'Horizontal' : 'Vertical'} edge at row ${row + 1}, column ${column + 1}, ${selected ? 'drawn' : 'empty'}',
        child: Material(
          key: ValueKey<String>('loop-edge-${edge.id}'),
          color: selected
              ? const Color(0x6671AFC0)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(hit / 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(hit / 2),
            onTap: enabled ? () => onToggle(edge) : null,
          ),
        ),
      ),
    );
  }
}

class _LoopPainter extends CustomPainter {
  const _LoopPainter({
    required this.puzzle,
    required this.version,
    required this.solved,
  });

  final LoopLogicPuzzle puzzle;
  final int version;
  final bool solved;

  static const _line = Color(0xFFC9DCE7);
  static const _loop = Color(0xFF61AFC0);
  static const _clue = Color(0xFF55718A);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / LoopLogicPuzzle.size;
    final fill = Paint()..color = const Color(0xFFF8FCFF);
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1.3;
    final loopPaint = Paint()
      ..color = solved ? const Color(0xFF79B98B) : _loop
      ..strokeWidth = max(4.0, cell * .09)
      ..strokeCap = StrokeCap.round;

    for (var row = 0; row < LoopLogicPuzzle.size; row++) {
      for (var column = 0; column < LoopLogicPuzzle.size; column++) {
        final rect = Rect.fromLTWH(
          column * cell + 1,
          row * cell + 1,
          cell - 2,
          cell - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * .12)),
          fill,
        );
        final clue = puzzle.clues[row][column].toString();
        final text = TextPainter(
          text: TextSpan(
            text: clue,
            style: TextStyle(
              color: _clue,
              fontSize: cell * .29,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(
            column * cell + (cell - text.width) / 2,
            row * cell + (cell - text.height) / 2,
          ),
        );
      }
    }

    for (var row = 0; row <= LoopLogicPuzzle.size; row++) {
      for (var column = 0; column < LoopLogicPuzzle.size; column++) {
        final edge = LoopEdge(
          row * LoopLogicPuzzle.vertexCount + column,
          row * LoopLogicPuzzle.vertexCount + column + 1,
        );
        canvas.drawLine(
          Offset(column * cell, row * cell),
          Offset((column + 1) * cell, row * cell),
          grid,
        );
        if (puzzle.selectedEdges.contains(edge)) {
          canvas.drawLine(
            Offset(column * cell, row * cell),
            Offset((column + 1) * cell, row * cell),
            loopPaint,
          );
        }
      }
    }
    for (var row = 0; row < LoopLogicPuzzle.size; row++) {
      for (var column = 0; column <= LoopLogicPuzzle.size; column++) {
        final edge = LoopEdge(
          row * LoopLogicPuzzle.vertexCount + column,
          (row + 1) * LoopLogicPuzzle.vertexCount + column,
        );
        canvas.drawLine(
          Offset(column * cell, row * cell),
          Offset(column * cell, (row + 1) * cell),
          grid,
        );
        if (puzzle.selectedEdges.contains(edge)) {
          canvas.drawLine(
            Offset(column * cell, row * cell),
            Offset(column * cell, (row + 1) * cell),
            loopPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoopPainter oldDelegate) =>
      version != oldDelegate.version || solved != oldDelegate.solved;
}

