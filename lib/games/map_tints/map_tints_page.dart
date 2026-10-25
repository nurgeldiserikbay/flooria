import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_tints_engine.dart';

/// Node coloring game with a connected visual graph and immediate feedback.
class MapTintsPage extends StatefulWidget {
  const MapTintsPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int taps, int mistakes) onSessionEnd;

  @override
  State<MapTintsPage> createState() => _MapTintsPageState();
}

class _MapTintsPageState extends State<MapTintsPage> {
  static const ink = Color(0xFF354D76);
  static const paints = [
    Color(0xFFF5AFA8),
    Color(0xFF87D8C8),
    Color(0xFFC4B6F5),
  ];

  late MapTintsSession game;
  int revision = 0;
  bool reported = false;
  bool triedWrong = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = MapTintsSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1291 + revision,
    );
    reported = false;
    triedWrong = false;
  }

  void _tap(int index) {
    if (reported || !game.tap(index)) return;
    setState(() => triedWrong = false);
  }

  void _check() {
    if (reported || !game.fullyColored) return;
    final passed = game.check();
    setState(() => triedWrong = !passed);
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.taps, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = game.conflicts;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FAFF),
        foregroundColor: ink,
        toolbarHeight: 48,
        title: const Text('Map Tints',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Center(
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7185A7),
                      fontSize: 12,
                    )),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD0EDF9),
                    Color(0xFFE8E4FC),
                    Color(0xFFFFEBD9),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.account_tree_rounded,
                        color: Color(0xFF7A81C4)),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text('Color every connected island',
                          style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                    Text('${game.round} / ${game.roundCount}',
                        style: const TextStyle(
                            color: Color(0xFF737DAC),
                            fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 7),
                  const Text(
                    'Connected dots must be different colors. Tap to cycle.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6880A3)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < paints.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: paints[i],
                                shape: BoxShape.circle,
                                border: Border.all(color: ink),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(['CORAL', 'MINT', 'LILAC'][i],
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: ink)),
                          ]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(builder: (context, area) {
                      final side = math.min(
                          area.maxWidth, math.min(area.maxHeight, 420.0));
                      return Center(
                        child: Container(
                          width: side,
                          height: side,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xF6FFFFFF),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                                color: const Color(0xFFBDCCE9), width: 2),
                          ),
                          child: LayoutBuilder(builder: (context, square) {
                            final diameter = math.min(56.0, square.maxWidth * .19);
                            final radius = square.maxWidth * .34;
                            final center = square.maxWidth / 2;
                            final positions = [
                              for (var i = 0; i < game.nodeCount; i++)
                                Offset(
                                  center +
                                      radius *
                                          math.cos(
                                              2 * math.pi * i / game.nodeCount -
                                                  math.pi / 2),
                                  center +
                                      radius *
                                          math.sin(
                                              2 * math.pi * i / game.nodeCount -
                                                  math.pi / 2),
                                ),
                            ];
                            return Stack(children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _GraphLines(
                                    positions, game.edges, conflicts),
                                ),
                              ),
                              for (var i = 0; i < game.nodeCount; i++)
                                Positioned(
                                  left: positions[i].dx - diameter / 2,
                                  top: positions[i].dy - diameter / 2,
                                  width: diameter,
                                  height: diameter,
                                  child: Material(
                                    color: game.colors[i] == null
                                        ? const Color(0xFFF2F7FF)
                                        : paints[game.colors[i]!],
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: conflicts.contains(i)
                                            ? const Color(0xFFCC5963)
                                            : game.fixed.containsKey(i)
                                                ? const Color(0xFF627B9B)
                                                : const Color(0xFF9AB1D3),
                                        width: conflicts.contains(i) ? 4 : 2,
                                      ),
                                    ),
                                    child: InkWell(
                                      key: ValueKey('map-tints-node-$i'),
                                      customBorder: const CircleBorder(),
                                      onTap: game.fixed.containsKey(i)
                                          ? null
                                          : () => _tap(i),
                                      child: Center(
                                        child: game.fixed.containsKey(i)
                                            ? const Icon(
                                                Icons.lock_rounded,
                                                size: 19,
                                                color: ink)
                                            : Text(
                                                '${i + 1}',
                                                style: const TextStyle(
                                                    color: ink,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                            ]);
                          }),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    game.complete
                        ? 'Wonderful! Every map is colored.'
                        : conflicts.isNotEmpty
                            ? 'Red outlines mean neighboring colors match.'
                            : triedWrong
                                ? 'Not yet. Check every connected pair.'
                                : 'Locked dots already have their color.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: Text('${game.taps} changes',
                          style: const TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900)),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('map-tints-check'),
                      onPressed: game.complete
                          ? () => setState(() {
                              revision++;
                              _restart();
                            })
                          : game.fullyColored
                              ? _check
                              : null,
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF7A77C5),
                      ),
                      icon: Icon(game.complete
                          ? Icons.restart_alt_rounded
                          : Icons.check_rounded),
                      label: Text(game.complete ? 'PLAY AGAIN' : 'CHECK'),
                    ),
                    IconButton(
                      tooltip: 'Restart',
                      onPressed: () => setState(() {
                        revision++;
                        _restart();
                      }),
                      icon: const Icon(Icons.refresh_rounded, color: ink),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphLines extends CustomPainter {
  const _GraphLines(this.positions, this.edges, this.conflicts);

  final List<Offset> positions;
  final List<(int, int)> edges;
  final Set<int> conflicts;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final conflict =
          conflicts.contains(edge.$1) && conflicts.contains(edge.$2);
      canvas.drawLine(
        positions[edge.$1],
        positions[edge.$2],
        Paint()
          ..strokeWidth = conflict ? 4 : 3
          ..strokeCap = StrokeCap.round
          ..color = conflict
              ? const Color(0xFFED9FA4)
              : const Color(0xFFA9B6D4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphLines oldDelegate) => true;
}
