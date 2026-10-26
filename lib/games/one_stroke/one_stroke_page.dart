import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'one_stroke_engine.dart';

class OneStrokePage extends StatefulWidget {
  const OneStrokePage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int invalidMoves) onSessionEnd;

  @override
  State<OneStrokePage> createState() => _OneStrokePageState();
}

class _OneStrokePageState extends State<OneStrokePage> {
  late OneStrokeSession game;
  int revision = 0;
  bool notified = false;
  bool badTap = false;
  static const ink = Color(0xFF354E79);

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = OneStrokeSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 1531 + revision);
    notified = false;
    badTap = false;
  }

  void _move(int node) {
    if (notified) return;
    final moved = game.move(node);
    setState(() => badTap = !moved);
    if (!game.complete || notified) return;
    notified = true;
    widget.onSessionEnd(game.round, game.totalMoves, game.invalidMoves);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF7FAFF),
        foregroundColor: ink,
        title: const Text('One Stroke',
          style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF7286A8), fontSize: 12)))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFCFEAFB), Color(0xFFE5E5FA),
              Color(0xFFFFE8D7)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.timeline_rounded,
                color: Color(0xFF7A80BD)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Trace every line once',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                  color: ink))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF7681AA))),
            ]),
            const SizedBox(height: 7),
            const Text('Tap a connected dot. Never reuse a line.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12,
                color: Color(0xFF667FA5))),
            const SizedBox(height: 12),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final side = math.min(bounds.maxWidth,
                  math.min(bounds.maxHeight, 430.0));
              return Center(child: Container(
                width: side, height: side,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xF9FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFB6C8E3), width: 2)),
                child: LayoutBuilder(builder: (context, board) {
                  final center = board.maxWidth / 2;
                  final radius = board.maxWidth * .35;
                  final diameter = math.min(55.0, board.maxWidth * .18);
                  final points = [
                    for (var i = 0; i < game.nodeCount; i++)
                      Offset(center + radius * math.cos(
                        2 * math.pi * i / game.nodeCount - math.pi / 2),
                        center + radius * math.sin(
                        2 * math.pi * i / game.nodeCount - math.pi / 2)),
                  ];
                  return Stack(children: [
                    Positioned.fill(child: CustomPaint(
                      painter: _StrokeLines(points, game.edges, game.visited))),
                    for (var i = 0; i < points.length; i++)
                      Positioned(
                        left: points[i].dx - diameter / 2,
                        top: points[i].dy - diameter / 2,
                        height: diameter, width: diameter,
                        child: Material(
                          color: i == game.current
                              ? const Color(0xFF87DCC1)
                              : const Color(0xFFDDD7FB),
                          shape: CircleBorder(side: BorderSide(
                            width: i == game.current ? 3 : 2,
                            color: i == game.current
                              ? const Color(0xFF4CA887)
                              : const Color(0xFF8D87C2))),
                          child: InkWell(
                            key: ValueKey('stroke-node-$i'),
                            customBorder: const CircleBorder(),
                            onTap: game.complete ? null : () => _move(i),
                            child: Center(child: i == game.current
                                ? const Icon(Icons.edit_location_alt_rounded,
                                    size: 24, color: ink)
                                : Text('${i + 1}',
                                    style: const TextStyle(color: ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          ),
                        ),
                      ),
                  ]);
                }),
              ));
            })),
            const SizedBox(height: 9),
            Text(game.complete ? 'Every trail completed!'
                : badTap ? 'Choose a connected dot with an unused line.'
                : 'Lines left: ${game.remaining}',
              style: const TextStyle(color: ink, fontSize: 12,
                fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${game.totalMoves} moves',
                style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 13))),
              TextButton.icon(
                onPressed: game.complete || game.history.isEmpty
                    ? null : () => setState(() {
                      game.undo();
                      badTap = false;
                    }),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('UNDO')),
              FilledButton.icon(
                key: const ValueKey('stroke-restart'),
                onPressed: () => setState(() { revision++; _restart(); }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7778C7),
                  foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'RESTART')),
            ]),
          ]),
        ),
      ))),
    );
  }
}

class _StrokeLines extends CustomPainter {
  const _StrokeLines(this.points, this.edges, this.visited);
  final List<Offset> points;
  final List<StrokeEdge> edges;
  final Set<int> visited;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      canvas.drawLine(points[edge.a], points[edge.b], Paint()
        ..strokeWidth = visited.contains(i) ? 6 : 4
        ..strokeCap = StrokeCap.round
        ..color = visited.contains(i)
            ? const Color(0xFF9AE3CB) : const Color(0xFF9CAFD3));
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeLines oldDelegate) => true;
}
