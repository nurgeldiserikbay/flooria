import 'dart:math';

import 'package:flutter/material.dart';

import 'shape_shift_engine.dart';

class ShapeShiftPage extends StatefulWidget {
  const ShapeShiftPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int elapsedMillis, int mistakes) onSessionEnd;

  @override
  State<ShapeShiftPage> createState() => _ShapeShiftPageState();
}

class _ShapeShiftPageState extends State<ShapeShiftPage> {
  late ShapeShiftSession session;
  final Stopwatch _clock = Stopwatch();
  int _revision = 0;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _clock
      ..stop()
      ..reset();
    _rewarded = false;
    session = ShapeShiftSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 130363 + _revision++,
    );
  }

  Future<void> _choose(int index) async {
    if (session.finished || _rewarded) return;
    if (!_clock.isRunning) _clock.start();
    final correct = session.puzzle.answerIndex == index;
    setState(() => session.choose(index));
    if (!correct) return;
    if (!session.finished) return;
    _clock.stop();
    _rewarded = true;
    widget.onSessionEnd(_clock.elapsedMilliseconds, session.mistakes);
    if (widget.floor == null) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Great rotation!', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You matched all three silhouettes in ${_clock.elapsedMilliseconds ~/ 1000}s.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w600)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('CONTINUE'),
        )],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(advance == true);
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final puzzle = session.puzzle;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Shape Shift', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _cream,
        foregroundColor: _ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _muted)),
            )),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.rotate_right_rounded, color: _violet, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Find the same shape after rotation',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text('${session.round + (complete ? 0 : 1)} / ${session.roundCount}',
                style: const TextStyle(color: _violet, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE9DDF5),
              color: _violet,
            )),
            const SizedBox(height: 10),
            const Text('REFERENCE SILHOUETTE', style: TextStyle(
              fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w900, color: _muted)),
            const SizedBox(height: 5),
            Expanded(flex: 5, child: Center(child: _ShapeBoard(
              cells: puzzle.target, color: const Color(0xFF9E8BD2), maxExtent: 190,
            ))),
            const SizedBox(height: 6),
            Text(complete ? 'All three shapes matched!' : 'Which piece is the same shape, turned?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Expanded(flex: 4, child: Row(
              children: List<Widget>.generate(puzzle.options.length, (index) =>
                Expanded(child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 7),
                  child: Semantics(button: true, label: 'Shape option ${index + 1}',
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(17),
                        onTap: complete ? null : () => _choose(index),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(children: [
                            Expanded(child: Center(child: _ShapeBoard(
                              cells: puzzle.options[index], color: _choiceColors[index],
                              maxExtent: 112,
                            ))),
                            Text(String.fromCharCode(65 + index), style: const TextStyle(
                              color: _muted, fontSize: 12, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('${session.mistakes} mismatches',
                style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700))),
              if (complete && widget.floor == null)
                FilledButton.icon(
                  onPressed: () => setState(_startSession),
                  style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('PLAY AGAIN'),
                ),
            ]),
          ]),
        ),
      ))),
    );
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }
}

class _ShapeBoard extends StatelessWidget {
  const _ShapeBoard({required this.cells, required this.color, required this.maxExtent});
  final List<ShapeCell> cells;
  final Color color;
  final double maxExtent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final rows = cells.map((cell) => cell.$1).reduce(max) + 1;
    final columns = cells.map((cell) => cell.$2).reduce(max) + 1;
    final size = min(maxExtent, min(constraints.maxWidth, constraints.maxHeight));
    if (!size.isFinite || size <= 0) return const SizedBox.shrink();
    final tile = min(size / columns, size / rows);
    return SizedBox(width: tile * columns, height: tile * rows,
      child: Column(children: List<Widget>.generate(rows, (row) => Expanded(
        child: Row(children: List<Widget>.generate(columns, (column) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: DecoratedBox(decoration: BoxDecoration(
              color: cells.contains((row, column)) ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            )),
          ),
        ))),
      ))),
    );
  });
}

const _cream = Color(0xFFFFF4E5);
const _ink = Color(0xFF76513D);
const _muted = Color(0xFF9B7B69);
const _violet = Color(0xFF9E8BD2);
const _choiceColors = <Color>[
  Color(0xFFFFD6A7), Color(0xFFB9DCCB), Color(0xFFF0C0BA),
];
