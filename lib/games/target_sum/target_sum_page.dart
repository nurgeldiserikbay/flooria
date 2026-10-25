import 'package:flutter/material.dart';

import 'target_sum_engine.dart';

class TargetSumPage extends StatefulWidget {
  const TargetSumPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int completedBoards, int mistakes) onSessionEnd;

  @override
  State<TargetSumPage> createState() => _TargetSumPageState();
}

class _TargetSumPageState extends State<TargetSumPage> {
  late TargetSumSession session;
  int _revision = 0;
  bool _reported = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _feedback = null;
    _feedbackIsError = false;
    session = TargetSumSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 32452843 + _revision++,
      level: widget.floor ?? 1,
    );
  }

  void _toggle(int tileIndex) {
    if (!session.toggle(tileIndex)) return;
    setState(() {
      _feedback = null;
      _feedbackIsError = false;
    });
  }

  void _submit() {
    final result = session.submit();
    if (result == SumSubmitResult.invalid) return;
    setState(() {
      _feedbackIsError = result == SumSubmitResult.wrong;
      _feedback = result == SumSubmitResult.wrong
          ? 'Not quite. Try a different group.'
          : 'Target reached!';
    });
    if (session.finished) _finish();
  }

  Future<void> _finish() async {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.completedBoards, session.mistakes);
    if (widget.floor == null || !session.passed) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Perfect combination!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You found all ${TargetSumSession.boardCount} targets with ${session.mistakes} mistakes.',
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
    final board = session.current;
    final selected = session.selected;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Target Sum', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _paper,
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.calculate_rounded, color: _blue, size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Build the target from number tiles.',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text(complete ? '${session.completedBoards} / 5' : '${session.boardIndex + 1} / 5',
                style: const TextStyle(color: _blue, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFDDEAF2),
              color: _blue,
            )),
            const SizedBox(height: 12),
            Expanded(child: complete
                ? _ResultsPanel(session: session, onRetry: () => setState(_startSession))
                : Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _sky,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Column(children: [
                        const Text('TARGET', style: TextStyle(color: _muted,
                          letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 1),
                        Text('${board.target}', style: const TextStyle(fontSize: 36,
                          height: 1.1, color: _ink, fontWeight: FontWeight.w900)),
                        Text('Choose ${board.chooseCount} tiles · selected sum ${session.selectedSum}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: Center(child: LayoutBuilder(builder: (context, constraints) {
                      final columns = board.tiles.length == 6 ? 3 : 4;
                      final spacing = 9.0;
                      final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: 9,
                        children: [
                          for (var index = 0; index < board.tiles.length; index++)
                            _NumberTile(
                              key: ValueKey('target-sum-tile-$index'),
                              value: board.tiles[index],
                              width: tileWidth,
                              selected: selected.contains(index),
                              onTap: () => _toggle(index),
                            ),
                        ],
                      );
                    }))),
                    const SizedBox(height: 8),
                    SizedBox(height: 22, child: Center(child: Text(
                      _feedback ?? '${session.mistakes} wrong groups · six allowed',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _feedbackIsError ? _coral : _muted,
                        fontSize: 12, fontWeight: FontWeight.w700),
                    ))),
                    const SizedBox(height: 7),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: selected.isEmpty ? null : () => setState(() {
                          session.clearSelection();
                          _feedback = null;
                        }),
                        icon: const Icon(Icons.backspace_outlined, size: 18),
                        label: const Text('CLEAR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: _blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton.icon(
                        onPressed: selected.length == board.chooseCount ? _submit : null,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('CHECK'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          disabledBackgroundColor: const Color(0xFFC7D7E1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      )),
                    ]),
                  ])),
          ]),
        ),
      ))),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    super.key,
    required this.value,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: width * .78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _blue : _tile,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x1F3E6075), blurRadius: 9, offset: Offset(0, 4))],
        ),
        child: Text('$value', style: TextStyle(
          fontSize: 25, fontWeight: FontWeight.w900,
          color: selected ? Colors.white : _ink)),
      ),
    ),
  );
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final TargetSumSession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(session.passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
        size: 62, color: session.passed ? _blue : _muted),
      const SizedBox(height: 10),
      Text(session.passed ? 'Numbers aligned!' : 'Keep practicing', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 8),
      Text('${session.completedBoards} of ${TargetSumSession.boardCount} targets · ${session.mistakes} mistakes',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      const Text('Solve all five. Six wrong groups are allowed.',
        textAlign: TextAlign.center, style: TextStyle(color: _muted)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
        label: const Text('PLAY AGAIN')),
    ],
  ));
}

const _paper = Color(0xFFF6FAFC);
const _ink = Color(0xFF40556B);
const _muted = Color(0xFF8294A3);
const _blue = Color(0xFF76A9C5);
const _sky = Color(0xFFDDEEF7);
const _tile = Color(0xFFF0E7D7);
const _coral = Color(0xFFCA8578);
