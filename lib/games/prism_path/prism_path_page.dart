import 'package:flutter/material.dart';

import 'prism_path_engine.dart';

/// Guide a beam through two mirrors and into a crystal across three boards.
class PrismPathPage extends StatefulWidget {
  const PrismPathPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int mistakes) onSessionEnd;

  @override
  State<PrismPathPage> createState() => _PrismPathPageState();
}

class _PrismPathPageState extends State<PrismPathPage> {
  late PrismPathSession session;
  int revision = 0;
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
    session = PrismPathSession(seed: seed);
    reported = false;
  }

  void _rotate(int row, int column) {
    if (!session.rotate(row, column)) return;
    setState(() {});
    if (!session.complete || reported) return;

    reported = true;
    widget.onSessionEnd(
      PrismPathSession.totalRounds,
      session.moves,
      session.mistakes,
    );
    if (widget.floor != null) widget.onComplete();
  }

  void _nextRound() {
    if (!session.advance()) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.complete;
    final puzzle = session.puzzle;
    final beam = finished ? <PrismCell>{} : puzzle.beamCells;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FC),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Prism Path',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF4FAFF),
        foregroundColor: const Color(0xFF426287),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDDF1FC),
                    Color(0xFFF2F7FF),
                    Color(0xFFE2F5EB),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFEEB34F),
                        size: 23,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          finished
                              ? 'Crystal charged!'
                              : session.roundComplete
                                  ? 'Path restored!'
                                  : 'Rotate mirrors to guide the light',
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
                        finished
                            ? '${PrismPathSession.totalRounds} / ${PrismPathSession.totalRounds}'
                            : '${session.round + 1} / ${PrismPathSession.totalRounds}',
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
                        final size = bounds.biggest.shortestSide
                            .clamp(0.0, 430.0)
                            .toDouble();
                        return Center(
                          child: SizedBox.square(
                            dimension: size,
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: PrismPuzzle.size,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount:
                                  PrismPuzzle.size * PrismPuzzle.size,
                              itemBuilder: (context, index) {
                                final cell = PrismCell(
                                  index ~/ PrismPuzzle.size,
                                  index % PrismPuzzle.size,
                                );
                                final mirror = finished
                                    ? null
                                    : puzzle.mirrorAt(cell);
                                final isSource = !finished &&
                                    cell == puzzle.source;
                                final isGoal = !finished && cell == puzzle.goal;
                                final illuminated = beam.contains(cell);
                                final interactive = mirror != null &&
                                    !finished &&
                                    !session.roundComplete;

                                return Semantics(
                                  button: interactive,
                                  label: isSource
                                      ? 'Light source'
                                      : isGoal
                                          ? 'Crystal goal'
                                          : mirror == null
                                              ? 'Board cell'
                                              : 'Mirror ${mirror.isDecoy ? "decoy" : ""}, ${mirror.face == MirrorFace.slash ? "slash" : "backslash"}',
                                  child: Material(
                                    color: illuminated
                                        ? const Color(0xFFFFF0BD)
                                        : const Color(0xFFF9FCFF),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: interactive
                                          ? () => _rotate(cell.row, cell.column)
                                          : null,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: illuminated
                                                ? const Color(0xFFFFD16E)
                                                : const Color(0xFFD8E7F1),
                                            width: illuminated ? 2 : 1,
                                          ),
                                          boxShadow: illuminated
                                              ? const [
                                                  BoxShadow(
                                                    color: Color(0x55FFD16E),
                                                    blurRadius: 10,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: isSource
                                              ? Icon(
                                                  Icons.wb_sunny_rounded,
                                                  size: size * .095,
                                                  color:
                                                      const Color(0xFFF0AD45),
                                                )
                                              : isGoal
                                                  ? Icon(
                                                      Icons.diamond_rounded,
                                                      size: size * .09,
                                                      color: const Color(
                                                        0xFF70C9BA,
                                                      ),
                                                    )
                                                  : mirror == null
                                                      ? null
                                                      : AnimatedRotation(
                                                          turns: mirror.face ==
                                                                  MirrorFace
                                                                      .slash
                                                              ? 0
                                                              : .5,
                                                          duration:
                                                              const Duration(
                                                            milliseconds: 180,
                                                          ),
                                                          child: Text(
                                                            '/',
                                                            style: TextStyle(
                                                              color: mirror
                                                                      .isDecoy
                                                                  ? const Color(
                                                                      0xFF97AFC4,
                                                                    )
                                                                  : const Color(
                                                                      0xFF627FA0,
                                                                    ),
                                                              fontSize:
                                                                  size * .13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                          ),
                                                        ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${session.moves} moves · ${session.mistakes} wrong turns',
                          style: const TextStyle(
                            color: Color(0xFF7892A9),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: finished
                            ? () => setState(() {
                                  revision++;
                                  _restart();
                                })
                            : session.roundComplete
                                ? _nextRound
                                : () => setState(() {
                                      revision++;
                                      _restart();
                                    }),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD98A),
                          foregroundColor: const Color(0xFF5C5D6C),
                        ),
                        icon: Icon(
                          finished || !session.roundComplete
                              ? Icons.refresh_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          finished
                              ? 'PLAY AGAIN'
                              : session.roundComplete
                                  ? 'NEXT PATH'
                                  : 'RESTART',
                        ),
                      ),
                    ],
                  ),
                  if (finished)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        'Three paths solved in ${session.moves} mirror turns.',
                        style: const TextStyle(
                          color: Color(0xFF527C70),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
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
