import 'dart:math';

import 'package:flutter/material.dart';

import 'clover_sweep_engine.dart';

class CloverSweepPage extends StatefulWidget {
  const CloverSweepPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int mineHits) onSessionEnd;

  @override
  State<CloverSweepPage> createState() => _CloverSweepPageState();
}

class _CloverSweepPageState extends State<CloverSweepPage> {
  late CloverSweepSession session;
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
    session = CloverSweepSession(seed: seed);
    reported = false;
  }

  void _reveal(int cell) {
    if (!session.reveal(cell)) return;
    setState(() {});
  }

  void _flag(int cell) {
    if (!session.toggleFlag(cell)) return;
    setState(() {});
  }

  void _advance() {
    if (!session.advance()) return;
    setState(() {});
    if (!session.complete || reported) return;
    reported = true;
    widget.onSessionEnd(
      CloverSweepSession.totalRounds,
      session.totalMineHits,
    );
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = session.puzzle;
    final complete = session.complete;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6EE),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Clover Sweep',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FBF6),
        foregroundColor: const Color(0xFF416B56),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'LEVEL ${widget.floor}',
                  style: const TextStyle(
                    color: Color(0xFF789783),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grass_rounded,
                          color: Color(0xFF79B88A), size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complete
                              ? 'The garden is safe!'
                              : session.roundComplete
                                  ? 'Patch cleared!'
                                  : 'Reveal clover; flag hidden thorns',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF416B56),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${complete ? CloverSweepSession.totalRounds : session.round + 1} / ${CloverSweepSession.totalRounds}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF719887),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Tap to reveal · hold to mark a thorn',
                    style: const TextStyle(
                      color: Color(0xFF789783),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final side = min(
                          430.0,
                          min(bounds.maxWidth, bounds.maxHeight),
                        );
                        return Center(
                          child: SizedBox.square(
                            dimension: side,
                            child: GridView.builder(
                              key: const ValueKey<String>('clover-grid'),
                              padding: const EdgeInsets.all(3),
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: CloverSweepPuzzle.size,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                              itemCount: CloverSweepPuzzle.cellCount,
                              itemBuilder: (context, index) {
                                final mineHit =
                                    puzzle.revealedMines.contains(index) ||
                                    (complete && puzzle.mines.contains(index));
                                final visible = complete ||
                                    puzzle.revealedSafeCells.contains(index) ||
                                    puzzle.revealedMines.contains(index);
                                final flagged =
                                    puzzle.flags.contains(index) && !visible;
                                final safeStart = index ==
                                        CloverSweepPuzzle.startCell &&
                                    !visible;
                                return _CloverCell(
                                  key: ValueKey<String>('clover-cell-$index'),
                                  label: _cellLabel(
                                    puzzle,
                                    index,
                                    visible,
                                    mineHit,
                                    flagged,
                                    safeStart,
                                  ),
                                  clue: puzzle.adjacentMines(index),
                                  visible: visible,
                                  mineHit: mineHit,
                                  flagged: flagged,
                                  safeStart: safeStart,
                                  enabled:
                                      !complete && !session.roundComplete,
                                  onTap: () => _reveal(index),
                                  onLongPress: () => _flag(index),
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
                          '${puzzle.flags.length} flags · ${session.totalMineHits} thorn hits · ${puzzle.remainingSafeCells} safe left',
                          maxLines: 2,
                          style: const TextStyle(
                            color: Color(0xFF789783),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: complete
                            ? () => setState(() {
                                  revision++;
                                  _restart();
                                })
                            : session.roundComplete
                                ? _advance
                                : () => setState(() {
                                      revision++;
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
                                  ? 'NEXT PATCH'
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

  String _cellLabel(
    CloverSweepPuzzle puzzle,
    int index,
    bool visible,
    bool mineHit,
    bool flagged,
    bool safeStart,
  ) {
    final row = index ~/ CloverSweepPuzzle.size + 1;
    final column = index % CloverSweepPuzzle.size + 1;
    if (mineHit) return 'Row $row column $column, thorn revealed';
    if (visible) {
      final count = puzzle.adjacentMines(index);
      return 'Row $row column $column, safe, $count neighboring thorns';
    }
    if (flagged) return 'Row $row column $column, flagged as thorn';
    if (safeStart) return 'Safe starting clover at row $row column $column';
    return 'Hidden patch at row $row column $column';
  }
}

class _CloverCell extends StatelessWidget {
  const _CloverCell({
    super.key,
    required this.label,
    required this.clue,
    required this.visible,
    required this.mineHit,
    required this.flagged,
    required this.safeStart,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final int clue;
  final bool visible;
  final bool mineHit;
  final bool flagged;
  final bool safeStart;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const _numbers = <Color>[
    Color(0xFF7C98B8),
    Color(0xFF69A77C),
    Color(0xFFDE9D63),
    Color(0xFFCC7776),
    Color(0xFF8879B7),
    Color(0xFF5C8993),
    Color(0xFF8C7060),
    Color(0xFF51646B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = mineHit
        ? const Color(0xFFF7C8B9)
        : visible
            ? const Color(0xFFFFFDF4)
            : safeStart
                ? const Color(0xFFBFE4C5)
                : flagged
                    ? const Color(0xFFF4D4C7)
                    : const Color(0xFFB8DCC0);
    return Semantics(
      button: enabled,
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: safeStart && !visible
                    ? const Color(0xFF75B184)
                    : const Color(0xFFD1E5D4),
                width: safeStart && !visible ? 2 : 1,
              ),
            ),
            child: Center(
              child: mineHit
                  ? const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD17B69), size: 21)
                  : flagged
                      ? const Icon(Icons.flag_rounded,
                          color: Color(0xFFE58C72), size: 19)
                      : visible && clue > 0
                          ? FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Text(
                                  '$clue',
                                  style: TextStyle(
                                    color: _numbers[clue.clamp(1, 8).toInt() - 1],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            )
                          : safeStart && !visible
                              ? const Icon(Icons.spa_rounded,
                                  color: Color(0xFF57966B), size: 20)
                              : null,
            ),
          ),
        ),
      ),
    );
  }
}
