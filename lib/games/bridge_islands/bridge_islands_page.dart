import 'package:flutter/material.dart';

import 'bridge_islands_engine.dart';

/// Standalone bridge-counting puzzle. No global state or persistence.
class BridgeIslandsPage extends StatefulWidget {
  const BridgeIslandsPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int taps, int wrongChecks) onSessionEnd;

  @override
  State<BridgeIslandsPage> createState() => _BridgeIslandsPageState();
}

class _BridgeIslandsPageState extends State<BridgeIslandsPage> {
  static const ink = Color(0xFF344B75);
  late BridgeIslandsSession game;
  bool reported = false;
  bool wrong = false;
  int revision = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = BridgeIslandsSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1301 + revision,
    );
    reported = false;
    wrong = false;
  }

  void _tap(int i) {
    if (reported || !game.tap(i)) return;
    setState(() => wrong = false);
  }

  void _check() {
    if (reported) return;
    final success = game.check();
    setState(() => wrong = !success);
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.taps, game.wrongChecks);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F3FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Bridge Islands',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                    color: Color(0xFF7186AB),
                    fontWeight: FontWeight.w900))),
            ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFCFEDF9), Color(0xFFE2E3FA),
              Color(0xFFFFEBDA)],
          )),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF7483BD)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Connect every island',
                style: TextStyle(color: ink, fontSize: 14,
                    fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF7382A9),
                    fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Each island needs exactly its numbered bridges.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontWeight: FontWeight.w800,
                  fontSize: 12)),
            const SizedBox(height: 5),
            const Text('Tap a bridge path: none → one → two → none.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF637AA0), fontSize: 12)),
            const SizedBox(height: 10),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final boardSide = bounds.biggest.shortestSide.clamp(0.0, 430.0);
              return Center(child: Container(
                width: boardSide,
                height: boardSide,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xF6FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFC0CDE5), width: 2),
                ),
                child: LayoutBuilder(builder: (context, area) {
                  final w = area.maxWidth;
                  final h = area.maxHeight;
                  final positions = <Offset>[
                    Offset(w * .15, h * .27),
                    Offset(w * .50, h * .27),
                    Offset(w * .85, h * .27),
                    Offset(w * .15, h * .73),
                    Offset(w * .50, h * .73),
                    Offset(w * .85, h * .73),
                  ];
                  final total = game.degreeTotals;
                  return Stack(children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _BridgePainter(
                        positions, game.bridges))),
                    for (var i = 0;
                        i < BridgeIslandsSession.edgeList.length; i++)
                      Positioned(
                        left: (positions[
                            BridgeIslandsSession.edgeList[i].a].dx +
                            positions[
                            BridgeIslandsSession.edgeList[i].b].dx) / 2 - 28,
                        top: (positions[
                            BridgeIslandsSession.edgeList[i].a].dy +
                            positions[
                            BridgeIslandsSession.edgeList[i].b].dy) / 2 - 22,
                        width: 56,
                        height: 44,
                        child: Material(
                          borderRadius: BorderRadius.circular(13),
                          color: game.bridges[i] == 0
                              ? const Color(0xFFECF5FF)
                              : const Color(0xFFA8DDE9),
                          child: InkWell(
                            key: ValueKey('bridge-edge-$i'),
                            borderRadius: BorderRadius.circular(13),
                            onTap: game.complete ? null : () => _tap(i),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: const Color(0xFF9EB8D3))),
                              child: Text(game.bridges[i] == 0 ? '+'
                                  : '${game.bridges[i]}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: ink)),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 0; i < 6; i++)
                      Positioned(
                        left: positions[i].dx - 25,
                        top: positions[i].dy - 25,
                        width: 50,
                        height: 50,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: total[i] == game.target[i]
                                ? const Color(0xFFA9E0C9)
                                : total[i] > game.target[i]
                                    ? const Color(0xFFF7B0AD)
                                    : const Color(0xFFFFDCA2),
                            border: Border.all(
                              color: const Color(0xFF7C9EB8), width: 3)),
                          child: Text('${game.target[i]}',
                            style: const TextStyle(color: ink,
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ]);
                }),
              ));
            })),
            const SizedBox(height: 8),
            Text(game.complete
              ? 'All islands connected!'
              : wrong
                  ? 'Check the numbers and connect every island.'
                  : 'Green = correct count. Red = too many bridges.',
              style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w800, fontSize: 12),
              textAlign: TextAlign.center),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${game.taps} taps',
                style: const TextStyle(color: ink,
                    fontSize: 12, fontWeight: FontWeight.w900))),
              FilledButton.icon(
                key: const ValueKey('bridge-check'),
                onPressed: game.complete
                    ? () => setState(() { revision++; _reset(); })
                    : _check,
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF7779C4)),
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
  const _BridgePainter(this.positions, this.bridges);
  final List<Offset> positions;
  final List<int> bridges;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < BridgeIslandsSession.edgeList.length; i++) {
      final edge = BridgeIslandsSession.edgeList[i];
      final a = positions[edge.a], b = positions[edge.b];
      canvas.drawLine(a, b, Paint()
        ..color = const Color(0xFFD4DFEC)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round);
      final count = bridges[i];
      for (var j = 0; j < count; j++) {
        final offset = count == 1 ? Offset.zero
            : Offset(a.dy == b.dy ? 0 : (j == 0 ? -6 : 6),
                a.dx == b.dx ? 0 : (j == 0 ? -6 : 6));
        canvas.drawLine(a + offset, b + offset, Paint()
          ..color = const Color(0xFF5B9DBA)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BridgePainter oldDelegate) => true;
}
