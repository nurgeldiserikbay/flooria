import 'dart:async';

import 'package:flutter/material.dart';

import 'quick_count_engine.dart';

class QuickCountPage extends StatefulWidget {
  const QuickCountPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int total) onSessionEnd;

  @override
  State<QuickCountPage> createState() => _QuickCountPageState();
}

class _QuickCountPageState extends State<QuickCountPage> {
  static const _flashDuration = Duration(milliseconds: 1350);
  static const _nextRoundDelay = Duration(milliseconds: 420);

  late QuickCountSession session;
  Timer? _timer;
  int _revision = 0;
  int _timerGeneration = 0;
  bool _flashVisible = true;
  bool _transitioning = false;
  bool _reported = false;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _cancelTimer();
    _reported = false;
    _transitioning = false;
    _flashVisible = true;
    _lastAnswerCorrect = null;
    session = QuickCountSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 73856093 + _revision++,
      level: widget.floor ?? 1,
    );
    _scheduleHide();
  }

  void _scheduleHide() {
    final generation = ++_timerGeneration;
    _timer?.cancel();
    _timer = Timer(_flashDuration, () {
      if (!mounted || generation != _timerGeneration || _transitioning) return;
      setState(() => _flashVisible = false);
    });
  }

  void _answer(int count) {
    if (_flashVisible || _transitioning || !session.answer(count)) return;
    _cancelTimer();
    final isCorrect = count == session.rounds[session.round - 1].target;
    setState(() {
      _flashVisible = false;
      _lastAnswerCorrect = isCorrect;
    });
    if (session.finished) {
      _finish();
      return;
    }
    _transitioning = true;
    final generation = _timerGeneration;
    _timer = Timer(_nextRoundDelay, () {
      if (!mounted || generation != _timerGeneration || session.finished) return;
      setState(() {
        _transitioning = false;
        _flashVisible = true;
        _lastAnswerCorrect = null;
      });
      _scheduleHide();
    });
  }

  Future<void> _finish() async {
    if (_reported || !session.finished) return;
    _reported = true;
    _cancelTimer();
    widget.onSessionEnd(session.correct, QuickCountSession.roundCount);
    if (widget.floor == null || !session.passed) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Great estimating!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You estimated ${session.correct} of ${QuickCountSession.roundCount} groups correctly.',
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

  void _cancelTimer() {
    _timerGeneration++;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final current = session.current;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Quick Count', style: TextStyle(fontWeight: FontWeight.w900)),
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
              const Icon(Icons.bubble_chart_rounded, color: _violet, size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Glance at the dots. Estimate the amount.',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text(complete ? '${session.correct} / 8' : '${session.round + 1} / 8',
                style: const TextStyle(color: _violet, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE7DDF2),
              color: _violet,
            )),
            const SizedBox(height: 12),
            Expanded(child: complete
                ? _ResultsPanel(session: session, onRetry: () => setState(_startSession))
                : Column(children: [
                    Expanded(child: Center(child: _DotCard(
                      round: current,
                      visible: _flashVisible,
                      transitioning: _transitioning,
                    ))),
                    const SizedBox(height: 10),
                    Text(
                      _flashVisible ? 'LOOK CLOSELY' : (_transitioning ? 'NEXT GROUP…' : 'HOW MANY DOTS?'),
                      style: const TextStyle(color: _muted, letterSpacing: 1.6,
                        fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 9),
                    Row(children: current.choices.map((choice) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _ChoiceButton(
                          count: choice,
                          enabled: !_flashVisible && !_transitioning,
                          onTap: () => _answer(choice),
                        ),
                      ),
                    )).toList()),
                    const SizedBox(height: 8),
                    SizedBox(height: 20, child: Center(child: Text(
                      _lastAnswerCorrect == null ? '${session.correct} correct so far' :
                          (_lastAnswerCorrect! ? 'That’s right!' : 'Good try — keep going'),
                      style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                    ))),
                  ])),
          ]),
        ),
      ))),
    );
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

class _DotCard extends StatelessWidget {
  const _DotCard({required this.round, required this.visible, required this.transitioning});

  final QuickCountRound round;
  final bool visible;
  final bool transitioning;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final width = bounds.maxWidth < 380 ? bounds.maxWidth : 380.0;
    final height = bounds.maxHeight < 320 ? bounds.maxHeight : 320.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: visible ? _lavender : const Color(0xFFF2EDF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x1F604C78), blurRadius: 18, offset: Offset(0, 7))],
      ),
      child: visible ? Stack(children: [
        for (final dot in round.dots)
          Positioned(
            left: dot.x * (width - 26),
            top: dot.y * (height - 26),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: _violet,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33734D9B), blurRadius: 5, offset: Offset(0, 2))],
              ),
            ),
          ),
      ]) : Center(child: Icon(
        transitioning ? Icons.check_circle_rounded : Icons.visibility_off_rounded,
        size: 48,
        color: transitioning ? _mint : const Color(0xFFB8AAC8),
      )),
    );
  });
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.count, required this.enabled, required this.onTap});

  final int count;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton(
      key: ValueKey('quick-count-choice-$count'),
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: _violet,
        disabledBackgroundColor: const Color(0xFFD9D0E3),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      child: Text('$count'),
    ),
  );
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final QuickCountSession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(session.passed ? Icons.auto_awesome_rounded : Icons.replay_rounded,
        size: 62, color: session.passed ? _violet : _muted),
      const SizedBox(height: 10),
      Text(session.passed ? 'Sharp eyes!' : 'Keep practicing', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 8),
      Text('${session.correct} of ${QuickCountSession.roundCount} estimates were exact',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
      if (!session.passed) ...[
        const SizedBox(height: 14),
        const Text('Six exact estimates unlock this level.',
          textAlign: TextAlign.center, style: TextStyle(color: _muted)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
          label: const Text('TRY AGAIN')),
      ],
    ],
  ));
}

const _paper = Color(0xFFFFF8EF);
const _ink = Color(0xFF514563);
const _muted = Color(0xFF95889F);
const _violet = Color(0xFF9A7BB8);
const _lavender = Color(0xFFEDE3F5);
const _mint = Color(0xFF73AD98);
