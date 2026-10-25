import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'bridge_cut_engine.dart';

class BridgeCutPage extends StatefulWidget {
  const BridgeCutPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int mistakes) onSessionEnd;

  @override
  State<BridgeCutPage> createState() => _BridgeCutPageState();
}

class _BridgeCutPageState extends State<BridgeCutPage> {
  late BridgeCutSession game;
  int revision = 0;
  bool reported = false;
  bool triedWrong = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = BridgeCutSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1223 + revision);
    reported = false;
    triedWrong = false;
  }

  void _tap(int index) {
    if (reported || !game.toggle(index)) return;
    setState(() => triedWrong = false);
  }

  void _check() {
    if (reported || game.removed.isEmpty) return;
    final success = game.check();
    setState(() => triedWrong = !success);
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.moves, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF344E79);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        toolbarHeight: 48,
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF7FBFF),
        title: const Text('Bridge Cut',
          style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  color: Color(0xFF7185A7), fontWeight: FontWeight.w900))),
            ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFCDECFB), Color(0xFFE6E3FB),
              Color(0xFFFFEADB)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.device_hub_rounded,
                color: Color(0xFF7784C0)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Separate blue and pink',
                style: TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 14))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF707AA9),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 7),
            const Text('Tap bridge numbers below to remove connections.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF687EA2), fontSize: 12)),
            const SizedBox(height: 7),
            Text('BRIDGE BUDGET: ${game.budget}  •  REMOVED: ${game.removed.length}',
              style: const TextStyle(color: ink, fontSize: 12,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final side = math.min(bounds.maxWidth,
                  math.min(bounds.maxHeight, 345.0));
              return Center(child: Container(
                width: side,
                height: side,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFBFCEEA), width: 2)),
                child: CustomPaint(
                  painter: _BridgePainter(
                    game.nodes, game.edges, game.removed),
                ),
              ));
            })),
            const SizedBox(height: 10),
            const Text('SELECT BRIDGES TO CUT',
              style: TextStyle(color: ink,
                fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            SizedBox(height: 98, child: Center(child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 7, runSpacing: 6,
              children: [
                for (var i = 0; i < game.edges.length; i++)
                  SizedBox(
                    width: 53, height: 40,
                    child: FilledButton(
                      key: ValueKey('bridge-cut-$i'),
                      onPressed: game.complete ? null : () => _tap(i),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: game.removed.contains(i)
                            ? const Color(0xFFF1A7AA)
                            : const Color(0xFFAACBEF),
                        foregroundColor: ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: Text('${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ))),
            const SizedBox(height: 8),
            Text(game.complete ? 'Every network separated!'
                : game.disconnected ? 'Disconnected! Confirm your cut.'
                : triedWrong ? 'Still connected. Try another set of bridges.'
                : 'Cut the fewest bridges to break every path.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink,
                fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${game.moves} actions',
                style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 12))),
              FilledButton.icon(
                key: const ValueKey('bridge-check'),
                onPressed: game.complete
                    ? () => setState(() { revision++; _reset(); })
                    : game.removed.isNotEmpty ? _check : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7A78C5),
                  foregroundColor: Colors.white),
                icon: Icon(game.complete
                    ? Icons.refresh_rounded : Icons.check_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'CHECK')),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() { revision++; _reset(); }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
          ]),
        ),
      ))),
    );
  }
}

class _BridgePainter extends CustomPainter {
  const _BridgePainter(this.nodes, this.edges, this.removed);
  final int nodes;
  final List<(int, int)> edges;
  final Set<int> removed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .37;
    final points = [
      for (var i = 0; i < nodes; i++)
        Offset(center.dx + radius * math.cos(2 * math.pi * i / nodes),
          center.dy + radius * math.sin(2 * math.pi * i / nodes)),
    ];
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final cut = removed.contains(i);
      final line = Paint()
        ..color = cut ? const Color(0xFFF1A4AA)
            : const Color(0xFF94AED5)
        ..strokeWidth = cut ? 2 : 4
        ..strokeCap = StrokeCap.round;
      if (!cut) {
        canvas.drawLine(points[edge.$1], points[edge.$2], line);
      } else {
        final middle = Offset(
          (points[edge.$1].dx + points[edge.$2].dx) / 2,
          (points[edge.$1].dy + points[edge.$2].dy) / 2);
        canvas.drawLine(points[edge.$1],
          Offset.lerp(points[edge.$1], middle, .7)!, line);
        canvas.drawLine(
          Offset.lerp(middle, points[edge.$2], .3)!,
          points[edge.$2], line);
      }
      final position = Offset.lerp(points[edge.$1], points[edge.$2], .5)!;
      final painter = TextPainter(
        text: TextSpan(text: '${i + 1}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
            color: cut ? const Color(0xFFAB4A61)
              : const Color(0xFF405D8B))),
        textDirection: TextDirection.ltr)..layout();
      canvas.drawCircle(position, 10,
        Paint()..color = const Color(0xFFF7FAFF));
      painter.paint(canvas, position - Offset(painter.width / 2,
        painter.height / 2));
    }
    for (var i = 0; i < nodes; i++) {
      canvas.drawCircle(points[i], 20,
        Paint()..color = i == 0 ? const Color(0xFF9BD0FA)
          : i == nodes - 1 ? const Color(0xFFF8AEBB)
          : const Color(0xFFDFD6FA));
      canvas.drawCircle(points[i], 20,
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF738BAC));
    }
  }

  @override
  bool shouldRepaint(covariant _BridgePainter oldDelegate) => true;
}
