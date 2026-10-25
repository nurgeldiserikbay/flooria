import 'dart:async';

import 'package:flutter/material.dart';

import 'signal_guard_engine.dart';

class SignalGuardPage extends StatefulWidget {
  const SignalGuardPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  /// Reports correctly handled signals and false alarms/missed targets.
  final void Function(int correctResponses, int errors) onSessionEnd;

  @override
  State<SignalGuardPage> createState() => _SignalGuardPageState();
}

class _SignalGuardPageState extends State<SignalGuardPage> {
  late SignalGuardSession session;
  Timer? _trialTimer;
  Timer? _transitionTimer;
  int _revision = 0;
  int _timerGeneration = 0;
  bool _transitioning = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _cancelTimers();
    _reported = false;
    _transitioning = false;
    session = SignalGuardSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 49979687 + _revision++,
    );
    _scheduleTrial();
  }

  void _scheduleTrial() {
    if (!mounted || session.finished) return;
    final generation = ++_timerGeneration;
    _trialTimer?.cancel();
    _trialTimer = Timer(const Duration(milliseconds: 1050), () {
      if (!mounted || generation != _timerGeneration || _transitioning) return;
      if (!session.timeout()) return;
      setState(() {});
      if (session.finished) {
        _finish();
      } else {
        _scheduleTrial();
      }
    });
  }

  void _tapSignal() {
    if (_transitioning || session.finished || !session.tap()) return;
    _trialTimer?.cancel();
    _timerGeneration++;
    setState(() => _transitioning = true);
    if (session.finished) {
      _finish();
      return;
    }
    final generation = _timerGeneration;
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || generation != _timerGeneration || session.finished) return;
      setState(() => _transitioning = false);
      _scheduleTrial();
    });
  }

  Future<void> _finish() async {
    if (_reported || !session.finished) return;
    _reported = true;
    _cancelTimers();
    widget.onSessionEnd(session.correctResponses, session.errors);
    if (widget.floor == null || !session.passed) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Signals secured!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You handled ${session.correctResponses} signals with ${session.errors} errors.',
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

  void _cancelTimers() {
    _timerGeneration++;
    _trialTimer?.cancel();
    _transitionTimer?.cancel();
    _trialTimer = null;
    _transitionTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final signal = session.currentSignal;
    final isTarget = signal == SignalKind.target;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Signal Guard', style: TextStyle(fontWeight: FontWeight.w900)),
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.ads_click_rounded, color: _teal, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Tap the star. Ignore the ring.',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text(complete ? '${session.correctResponses} / 12' : '${session.round + 1} / 12',
                style: const TextStyle(color: _teal, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFD9ECE7),
              color: _teal,
            )),
            const SizedBox(height: 12),
            Expanded(child: complete
                ? _ResultsPanel(session: session)
                : Center(child: LayoutBuilder(builder: (context, bounds) {
                    final size = bounds.biggest.shortestSide.clamp(0.0, 340.0).toDouble();
                    final color = isTarget ? _mint : _coral;
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(isTarget ? 'TAP NOW' : 'HOLD', style: TextStyle(
                        color: isTarget ? _teal : _muted,
                        letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 14),
                      Semantics(
                        button: true,
                        label: isTarget ? 'Star target. Tap now.' : 'Ring distractor. Do not tap.',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: const ValueKey('signal-card'),
                            customBorder: const CircleBorder(),
                            onTap: _transitioning ? null : _tapSignal,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 8),
                                boxShadow: const [BoxShadow(
                                  color: Color(0x1F76513D), blurRadius: 22, offset: Offset(0, 8))],
                              ),
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 120),
                                child: Icon(
                                  isTarget ? Icons.star_rounded : Icons.circle_outlined,
                                  key: ValueKey<int>(session.round),
                                  size: size * .43,
                                  color: isTarget ? Colors.white : const Color(0xFFAD7869),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(_transitioning ? 'Next signal…' : 'Wait for the next signal',
                        style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                    ]);
                  })),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text(complete
                  ? 'Errors: ${session.errors} · ${session.passed ? 'Passed' : 'Try again'}'
                  : '${session.correctResponses} handled · ${session.errors} errors',
                style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700))),
              if (complete && (widget.floor == null || !session.passed))
                FilledButton.icon(
                  onPressed: () => setState(_startSession),
                  style: FilledButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('TRY AGAIN'),
                ),
            ]),
          ]),
        ),
      ))),
    );
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session});
  final SignalGuardSession session;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(session.passed ? Icons.verified_rounded : Icons.replay_rounded,
        size: 62, color: session.passed ? _teal : _coral),
      const SizedBox(height: 10),
      Text(session.passed ? 'Good control!' : 'Keep practicing', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 8),
      Text('${session.correctResponses} signals handled · ${session.errors} errors',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
      if (!session.passed) ...[
        const SizedBox(height: 14),
        const Text('Aim for three errors or fewer.',
          textAlign: TextAlign.center, style: TextStyle(color: _muted)),
      ],
    ],
  ));
}

const _cream = Color(0xFFFFF4E5);
const _ink = Color(0xFF76513D);
const _muted = Color(0xFF9B7B69);
const _teal = Color(0xFF70A99A);
const _mint = Color(0xFF9BCDB9);
const _coral = Color(0xFFF0C3B5);
