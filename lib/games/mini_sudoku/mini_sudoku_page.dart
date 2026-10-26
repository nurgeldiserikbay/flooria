import 'package:flutter/material.dart';

import 'mini_sudoku_engine.dart';

/// Standalone 4x4 deduction puzzle. Shell owns floor and stats persistence.
class MiniSudokuPage extends StatefulWidget {
  const MiniSudokuPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int edits, int mistakes) onSessionEnd;

  @override
  State<MiniSudokuPage> createState() => _MiniSudokuPageState();
}

class _MiniSudokuPageState extends State<MiniSudokuPage> {
  static const ink = Color(0xFF344C77);
  late MiniSudokuSession game;
  int revision = 0;
  bool reported = false;
  bool wrong = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = MiniSudokuSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1627 + revision);
    reported = false;
    wrong = false;
  }

  void _tap(int cell) {
    if (reported || !game.tap(cell)) return;
    setState(() => wrong = false);
  }

  void _check() {
    if (reported || !game.filled) return;
    final success = game.check();
    setState(() => wrong = !success);
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.edits, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final clashes = game.conflicts;
    return Scaffold(
      backgroundColor: const Color(0xFFEDF5FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Mini Sudoku',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 12, color: Color(0xFF7688AB)))),
            ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFD0ECFC), Color(0xFFE7E2FA),
              Color(0xFFFFEDDC)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.grid_on_rounded,
                  color: Color(0xFF7776BD)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Fill the missing numbers',
                style: TextStyle(color: ink, fontSize: 14,
                    fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF7680AE),
                    fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 9),
            const Text(
              'Use 1–4 once in every row, column and 2×2 box.',
              style: TextStyle(color: Color(0xFF627BA4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(child: LayoutBuilder(builder: (context, space) {
              final side = space.biggest.shortestSide.clamp(0.0, 400.0);
              return Center(child: Container(
                width: side,
                height: side,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFAFFFFFF),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: const Color(0xFFC0CCEB),
                      width: 2)),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 16,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    final given = game.clues[index] != 0;
                    final value = game.board[index];
                    final conflict = clashes.contains(index);
                    final alternate = ((index ~/ 4) ~/ 2 +
                      (index % 4) ~/ 2).isEven;
                    return Semantics(
                      button: !given,
                      label: given ? 'Given number $value'
                        : value == 0 ? 'Empty cell' : 'Number $value',
                      child: Material(
                        color: conflict
                          ? const Color(0xFFFFC7C3)
                          : given
                            ? const Color(0xFFBFD7ED)
                            : alternate
                              ? const Color(0xFFEDE8FD)
                              : const Color(0xFFF3F9FF),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          key: ValueKey('sudoku-cell-$index'),
                          borderRadius: BorderRadius.circular(13),
                          onTap: given ? null : () => _tap(index),
                          child: Center(
                            child: value == 0
                              ? const Icon(Icons.add_rounded,
                                  color: Color(0xFFADB8CE), size: 19)
                              : Text('$value', style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 27,
                                  color: conflict
                                      ? const Color(0xFFB55263)
                                      : given
                                        ? const Color(0xFF405C86)
                                        : const Color(0xFF8077C5))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ));
            })),
            const SizedBox(height: 12),
            Text(game.complete
                ? 'Excellent! All three grids solved.'
                : clashes.isNotEmpty
                    ? 'Red cells repeat a number in a group.'
                    : wrong
                        ? 'That is not correct yet. Try again.'
                        : 'Tap a free cell to cycle 1, 2, 3, 4 and empty.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink, fontSize: 12,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${game.edits} edits',
                  style: const TextStyle(color: ink,
                    fontWeight: FontWeight.w900, fontSize: 12))),
              FilledButton.icon(
                key: const ValueKey('sudoku-check'),
                onPressed: game.complete
                  ? () => setState(() { revision++; _reset(); })
                  : game.filled ? _check : null,
                icon: Icon(game.complete
                    ? Icons.refresh_rounded : Icons.check_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'CHECK'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF7977C6))),
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
