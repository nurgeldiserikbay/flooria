import 'dart:math';

import 'package:flutter/material.dart';

import 'balance_beam_engine.dart';

class BalanceBeamPage extends StatefulWidget {
  const BalanceBeamPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int elapsedMillis, int mistakes) onSessionEnd;

  @override
  State<BalanceBeamPage> createState() => _BalanceBeamPageState();
}

class _BalanceBeamPageState extends State<BalanceBeamPage> {
  late BalanceBeamSession session;
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
    session = BalanceBeamSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 104729 + _revision++,
    );
  }

  void _place(int index) {
    if (session.finished) return;
    if (!_clock.isRunning) _clock.start();
    setState(() => session.place(index));
  }

  Future<void> _next() async {
    if (!session.advance()) return;
    setState(() {});
    if (!session.finished) return;
    _clock.stop();
    if (_rewarded) return;
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
        title: const Text('Perfect balance!', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You balanced all three scales in ${_clock.elapsedMilliseconds ~/ 1000}s.',
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
    final puzzle = session.puzzle;
    final completed = session.finished;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Balance Beam', style: TextStyle(fontWeight: FontWeight.w900)),
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
              const Icon(Icons.balance_rounded, color: _orange, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Choose weights to balance the beam',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text('${session.round + (completed ? 0 : 1)} / ${session.roundCount}',
                style: const TextStyle(color: _orange, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFFFE2CA),
              color: _orange,
            )),
            const SizedBox(height: 12),
            Expanded(child: Column(children: [
              Expanded(flex: 5, child: Center(child: _BalanceScale(
                target: puzzle.targetWeight,
                placed: session.placedWeight,
                balanced: session.balanced,
              ))),
              const SizedBox(height: 8),
              Text(session.balanced
                  ? 'Balanced! Continue to the next scale.'
                  : 'Add ${session.remainingWeight} more to the right pan',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(flex: 4, child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: puzzle.weights.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final selected = session.placedIndices.contains(index);
                  return Semantics(button: true,
                    label: 'Weight ${puzzle.weights[index]}${selected ? ', placed' : ''}',
                    child: Material(
                      color: selected ? const Color(0xFFE7F2EA) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: completed ? null : () {
                          if (selected) {
                            setState(() => session.remove(index));
                          } else {
                            _place(index);
                          }
                        },
                        child: Center(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${puzzle.weights[index]}', style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w900, color: _ink)),
                            if (selected) const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded, size: 17, color: _green),
                            ),
                          ],
                        )),
                      ),
                    ),
                  );
                },
              )),
            ])),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('${session.mistakes} overweight picks',
                style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700))),
              if (completed && widget.floor == null)
                FilledButton.icon(
                  onPressed: () => setState(_startSession),
                  style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('PLAY AGAIN'),
                )
              else
                FilledButton.icon(
                  onPressed: session.balanced ? _next : null,
                  style: FilledButton.styleFrom(backgroundColor: _orange,
                    foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE8D8C9)),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(session.round == session.roundCount - 1 ? 'FINISH' : 'NEXT'),
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

class _BalanceScale extends StatelessWidget {
  const _BalanceScale({required this.target, required this.placed, required this.balanced});
  final int target;
  final int placed;
  final bool balanced;

  @override
  Widget build(BuildContext context) {
    final tilt = balanced ? 0.0 : (placed - target).sign * 0.035;
    return LayoutBuilder(builder: (context, constraints) {
      final width = min(constraints.maxWidth, 390.0);
      return SizedBox(width: width, child: Stack(alignment: Alignment.center, children: [
        Positioned(top: 18, child: Transform.rotate(angle: tilt, child: Container(
          width: width * .76, height: 10,
          decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8)),
        ))),
        Positioned(top: 22, left: width * .13, child: _Pan(label: '$target', filled: true)),
        Positioned(top: 22, right: width * .13, child: _Pan(label: '$placed', filled: placed > 0)),
        Positioned(bottom: 4, child: Container(
          width: 28, height: constraints.maxHeight * .61,
          decoration: const BoxDecoration(
            color: Color(0xFFEFB784),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
        )),
        Positioned(bottom: 0, child: Container(
          width: 110, height: 16,
          decoration: BoxDecoration(color: const Color(0xFFD99869),
            borderRadius: BorderRadius.circular(12)),
        )),
      ]));
    });
  }
}

class _Pan extends StatelessWidget {
  const _Pan({required this.label, required this.filled});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 2, height: 42, color: const Color(0xFFC98C62)),
    Container(
      width: 78, height: 46,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFFD6A7) : const Color(0xFFFFF8EE),
        border: Border.all(color: const Color(0xFFE2B98F), width: 2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
    ),
  ]);
}

const _cream = Color(0xFFFFF4E5);
const _ink = Color(0xFF76513D);
const _muted = Color(0xFF9B7B69);
const _orange = Color(0xFFE99A5E);
const _green = Color(0xFF6DA986);
