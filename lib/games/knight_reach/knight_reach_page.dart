import 'package:flutter/material.dart';

import 'knight_reach_engine.dart';

class KnightReachPage extends StatefulWidget {
  const KnightReachPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int invalidMoves) onSessionEnd;

  @override
  State<KnightReachPage> createState() => _KnightReachPageState();
}

class _KnightReachPageState extends State<KnightReachPage> {
  static const ink = Color(0xFF344D75);
  late KnightReachSession session;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = KnightReachSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1429 + revision,
    );
    reported = false;
  }

  void _move(int cell) {
    if (reported || !session.move(cell)) return;
    setState(() {});
    if (reported || !session.complete) return;
    reported = true;
    widget.onSessionEnd(
        session.round, session.totalMoves, session.invalidMoves);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final legal = session.legalMoves.toSet();
    return Scaffold(
      backgroundColor: const Color(0xFFE9F5FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Knight Reach',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF6FBFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        color: Color(0xFF7588A8),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 490),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD1EDFA),
                    Color(0xFFE4E5FC),
                    Color(0xFFFFEBDC),
                  ],
                ),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.extension_rounded,
                      color: Color(0xFF7C86BD)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Find the way to the star',
                        style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ),
                  Text('${session.round} / ${session.roundCount}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7680A8))),
                ]),
                const SizedBox(height: 10),
                const Text('Jump like a chess knight: two squares and one turn.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF657BA0))),
                const SizedBox(height: 10),
                Expanded(child: LayoutBuilder(builder: (context, bounds) {
                  final width = bounds.biggest.shortestSide.clamp(0.0, 440.0);
                  return Center(
                    child: Container(
                      width: width,
                      height: width,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        color: const Color(0xF8FFFFFF),
                        border: Border.all(
                            color: const Color(0xFFBECBE7), width: 2),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: KnightReachSession.cellCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: KnightReachSession.side,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemBuilder: (context, cell) {
                          final isBlocked = session.blocked.contains(cell);
                          final isKnight =
                              !session.complete && cell == session.position;
                          final isTarget =
                              !session.complete && cell == session.goal;
                          final reachable = legal.contains(cell);
                          final base = (cell ~/ 5 + cell % 5).isEven
                              ? const Color(0xFFE4ECFA)
                              : const Color(0xFFF5F9FF);
                          return Material(
                            color: isBlocked
                                ? const Color(0xFFB7C4D5)
                                : reachable
                                    ? const Color(0xFFA9E1CF)
                                    : isTarget
                                        ? const Color(0xFFFFE0A4)
                                        : base,
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              key: ValueKey('knight-cell-$cell'),
                              borderRadius: BorderRadius.circular(11),
                              onTap: reachable ? () => _move(cell) : null,
                              child: Center(
                                child: Icon(
                                  isKnight
                                      ? Icons.pets_rounded
                                      : isTarget
                                          ? Icons.star_rounded
                                          : isBlocked
                                              ? Icons.close_rounded
                                              : reachable
                                                  ? Icons.circle_outlined
                                                  : Icons.circle,
                                  size: isKnight || isTarget ? 27 : 15,
                                  color: isKnight
                                      ? const Color(0xFF6569BA)
                                      : isTarget
                                          ? const Color(0xFFDD9B46)
                                          : isBlocked
                                              ? const Color(0xFF8496B0)
                                              : reachable
                                                  ? const Color(0xFF4BA688)
                                                  : const Color(0x00FFFFFF),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 9),
                Text(
                  session.complete
                      ? 'All destinations reached!'
                      : 'Green squares are legal jumps. Grey squares are blocked.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: ink, fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 9),
                Row(children: [
                  Expanded(
                    child: Text('${session.totalMoves} jumps',
                        style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('knight-restart'),
                    onPressed: () => setState(() {
                      revision++;
                      _restart();
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label:
                        Text(session.complete ? 'PLAY AGAIN' : 'RESTART'),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF777AC3),
                        foregroundColor: Colors.white),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
