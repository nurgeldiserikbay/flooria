import 'package:flutter/material.dart';

import 'paper_fold_engine.dart';

/// Spatial reasoning game: predict holes after unfolding a sheet of paper.
/// App shell owns campaign progression and persisted statistics.
class PaperFoldPage extends StatefulWidget {
  const PaperFoldPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int attempts, int mistakes) onSessionEnd;

  @override
  State<PaperFoldPage> createState() => _PaperFoldPageState();
}

class _PaperFoldPageState extends State<PaperFoldPage> {
  late PaperFoldSession session;
  int revision = 0;
  bool rewarded = false;
  bool showMistake = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = PaperFoldSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1847 + revision);
    rewarded = false;
    showMistake = false;
  }

  void _tap(int index) {
    if (rewarded || !session.toggle(index)) return;
    setState(() => showMistake = false);
  }

  void _check() {
    if (rewarded || session.selected.isEmpty) return;
    final right = session.check();
    setState(() => showMistake = !right);
    if (rewarded || !session.complete) return;
    rewarded = true;
    widget.onSessionEnd(session.round, session.attempts, session.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  String get instruction => switch (session.fold) {
    PaperFold.left => 'Right half folded onto LEFT',
    PaperFold.right => 'Left half folded onto RIGHT',
    PaperFold.top => 'Bottom half folded onto TOP',
    PaperFold.bottom => 'Top half folded onto BOTTOM',
    PaperFold.both => 'Fold to RIGHT, then to BOTTOM',
  };

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF324D7B);
    return Scaffold(
      backgroundColor: const Color(0xFFE5F0FF),
      appBar: AppBar(
        title: const Text('Paper Fold',
            style: TextStyle(fontWeight: FontWeight.w900)),
        toolbarHeight: 48,
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF3F9FF),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6980A5))))),
        ],
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC9EBFC),
                  Color(0xFFE6E3FB),
                  Color(0xFFFFE9D9),
                ],
              ),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.filter_none_rounded,
                    color: Color(0xFF717CC4)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Find every hidden hole',
                    style: TextStyle(color: ink,
                        fontSize: 14, fontWeight: FontWeight.w900))),
                Text('${session.round} / ${session.roundCount}',
                    style: const TextStyle(
                        color: Color(0xFF717BA5),
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 5),
              Text(instruction,
                  key: const ValueKey('paper-fold-instruction'),
                  style: const TextStyle(color: Color(0xFF6675A5),
                      fontWeight: FontWeight.w800, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 9),
              Expanded(child: LayoutBuilder(builder: (context, dimensions) {
                // Both boards and labels share an explicitly bounded layout.
                final width = dimensions.maxWidth;
                final height = dimensions.maxHeight;
                final unfoldedSide = (height * .52)
                    .clamp(0.0, width * .83).toDouble();
                final previewSide = (height * .27)
                    .clamp(0.0, width * .46).toDouble();
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('FOLDED SHEET',
                        style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1)),
                    SizedBox(
                      width: previewSide * session.foldedColumns /
                          PaperFoldSession.size,
                      height: previewSide * session.foldedRows /
                          PaperFoldSession.size,
                      child: _grid(
                        rows: session.foldedRows,
                        columns: session.foldedColumns,
                        readOnly: true,
                        cellSize: previewSide /
                            PaperFoldSession.size,
                      ),
                    ),
                    const Text('AFTER UNFOLDING — TAP HOLES',
                        style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: .4)),
                    SizedBox(
                      width: unfoldedSide,
                      height: unfoldedSide,
                      child: _grid(
                        rows: PaperFoldSession.size,
                        columns: PaperFoldSession.size,
                        readOnly: false,
                        cellSize: unfoldedSide /
                            PaperFoldSession.size,
                      ),
                    ),
                  ],
                ));
              })),
              const SizedBox(height: 6),
              Text(session.complete
                      ? 'Amazing! All sheets unfolded.'
                      : showMistake
                          ? 'Not quite. Imagine how the paper opens.'
                          : 'Tap a square to mark or unmark a hole.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: showMistake
                          ? const Color(0xFFAB6470)
                          : const Color(0xFF6378A5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('${session.attempts} checks',
                    style: const TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900))),
                FilledButton.icon(
                  key: const ValueKey('paper-fold-check'),
                  onPressed: session.complete
                      ? () => setState(() {
                          revision++;
                          _restart();
                        })
                      : session.selected.isEmpty ? null : _check,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7977BF),
                      foregroundColor: Colors.white),
                  icon: Icon(session.complete
                      ? Icons.refresh_rounded : Icons.check_rounded),
                  label: Text(session.complete ? 'PLAY AGAIN' : 'CHECK'),
                ),
                IconButton(
                  tooltip: 'Restart',
                  onPressed: () => setState(() {
                    revision++;
                    _restart();
                  }),
                  icon: const Icon(Icons.restart_alt_rounded, color: ink),
                ),
              ]),
            ]),
          ),
        )),
      ),
    );
  }

  Widget _grid({
    required int rows,
    required int columns,
    required bool readOnly,
    required double cellSize,
  }) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * columns,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final filled = readOnly
            ? session.punches.contains(index)
            : session.selected.contains(index);
        return Material(
          color: filled
              ? readOnly
                  ? const Color(0xFFFFD19F)
                  : const Color(0xFFA2D9F1)
              : const Color(0xF6FFFFFF),
          child: InkWell(
            key: ValueKey(readOnly
                ? 'paper-fold-punch-$index'
                : 'paper-fold-cell-$index'),
            onTap: readOnly ? null : () => _tap(index),
            child: Container(
              decoration: BoxDecoration(border: Border.all(
                color: const Color(0xFFBAC9E6), width: 1)),
              child: filled
                  ? Center(child: Icon(
                      readOnly ? Icons.circle_rounded : Icons.adjust_rounded,
                      size: cellSize * .45,
                      color: readOnly
                          ? const Color(0xFFAD7246)
                          : const Color(0xFF407BAF)))
                  : null,
            ),
          ),
        );
      },
    );
  }
}
