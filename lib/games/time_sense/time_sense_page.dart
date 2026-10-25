import 'dart:async';

import 'package:flutter/material.dart';

import 'time_sense_engine.dart';

class TimeSensePage extends StatefulWidget {
  const TimeSensePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int accurateRounds, int totalRounds) onSessionEnd;

  @override
  State<TimeSensePage> createState() => _TimeSensePageState();
}

class _TimeSensePageState extends State<TimeSensePage> {
  static const _resultPause = Duration(milliseconds: 850);

  late TimeSenseSession session;
  Stopwatch? _stopwatch;
  Timer? _limitTimer;
  Timer? _nextRoundTimer;
  int _revision = 0;
  int _timerGeneration = 0;
  bool _running = false;
  bool _transitioning = false;
  bool _reported = false;
  TimeSenseResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _cancelTimers();
    _running = false;
    _transitioning = false;
    _reported = false;
    _lastResult = null;
    session = TimeSenseSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 982451653 + _revision++,
      level: widget.floor ?? 1,
    );
  }

  void _startRound() {
    if (_running || _transitioning || session.finished) return;
    _stopwatch = Stopwatch()..start();
    _timerGeneration++;
    final generation = _timerGeneration;
    _limitTimer?.cancel();
    _limitTimer = Timer(
      const Duration(milliseconds: TimeSenseSession.maximumAttemptMillis),
      () {
        if (!mounted || generation != _timerGeneration || !_running) return;
        _submit(TimeSenseSession.maximumAttemptMillis);
      },
    );
    setState(() {
      _running = true;
      _lastResult = null;
    });
  }

  void _stopRound() {
    if (!_running || _transitioning) return;
    _stopwatch?.stop();
    _submit(_stopwatch?.elapsedMilliseconds ?? 0);
  }

  void _submit(int elapsedMillis) {
    if (!_running || !session.submit(elapsedMillis)) return;
    _limitTimer?.cancel();
    _limitTimer = null;
    _timerGeneration++;
    final result = session.results.last;
    setState(() {
      _running = false;
      _transitioning = true;
      _lastResult = result;
    });
    if (session.finished) {
      _finish();
      return;
    }
    final generation = _timerGeneration;
    _nextRoundTimer?.cancel();
    _nextRoundTimer = Timer(_resultPause, () {
      if (!mounted || generation != _timerGeneration || session.finished) return;
      setState(() {
        _transitioning = false;
        _lastResult = null;
      });
    });
  }

  Future<void> _finish() async {
    if (_reported || !session.finished) return;
    _reported = true;
    _cancelTimers();
    widget.onSessionEnd(session.accurateCount, TimeSenseSession.roundCount);
    if (widget.floor == null || !session.passed) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Well timed!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You sensed ${session.accurateCount} of ${TimeSenseSession.roundCount} intervals accurately.',
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
    _limitTimer?.cancel();
    _nextRoundTimer?.cancel();
    _limitTimer = null;
    _nextRoundTimer = null;
    _stopwatch?.stop();
  }

  String _seconds(int milliseconds) => (milliseconds / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final current = session.current;
    final last = _lastResult;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Time Sense', style: TextStyle(fontWeight: FontWeight.w900)),
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
              const Icon(Icons.hourglass_bottom_rounded, color: _coral, size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Feel the interval. Stop from memory.',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text(complete ? '${session.accurateCount} / 5' : '${session.round + 1} / 5',
                style: const TextStyle(color: _coral, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFF3DDD2),
              color: _coral,
            )),
            const SizedBox(height: 12),
            Expanded(child: complete
                ? _ResultsPanel(session: session, onRetry: () => setState(_startSession))
                : Column(children: [
                    Expanded(child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TARGET', style: TextStyle(color: _muted, letterSpacing: 2,
                          fontSize: 11, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('${_seconds(current.targetMillis)}s',
                          style: const TextStyle(fontSize: 42, height: 1,
                            color: _ink, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 24),
                        _TimeOrb(active: _running, transitioning: _transitioning),
                        const SizedBox(height: 23),
                        Text(
                          _running ? 'Tap STOP when it feels right.' :
                              _transitioning && last != null
                                  ? 'You stopped at ${_seconds(last.elapsedMillis)}s · ${last.accurate ? 'close!' : 'next one'}'
                                  : 'No clock. Trust your inner rhythm.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        key: ValueKey(_running ? 'time-sense-stop' : 'time-sense-start'),
                        onPressed: _transitioning ? null : (_running ? _stopRound : _startRound),
                        style: FilledButton.styleFrom(
                          backgroundColor: _coral,
                          disabledBackgroundColor: const Color(0xFFE9D4CB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        child: Text(_running ? 'STOP' : 'START'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${session.accurateCount} close estimates · within 20%',
                      style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  ])),
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

class _TimeOrb extends StatelessWidget {
  const _TimeOrb({required this.active, required this.transitioning});

  final bool active;
  final bool transitioning;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    width: active ? 126 : 108,
    height: active ? 126 : 108,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? const Color(0xFFFFD5C7) : const Color(0xFFFFE8DC),
      border: Border.all(color: Colors.white, width: 7),
      boxShadow: const [BoxShadow(color: Color(0x26785D50), blurRadius: 18, offset: Offset(0, 6))],
    ),
    child: Icon(
      transitioning ? Icons.check_rounded : Icons.hourglass_empty_rounded,
      color: transitioning ? _mint : _coral,
      size: 40,
    ),
  );
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final TimeSenseSession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(session.passed ? Icons.timer_rounded : Icons.replay_rounded,
        size: 62, color: session.passed ? _coral : _muted),
      const SizedBox(height: 10),
      Text(session.passed ? 'In your own time' : 'Keep practicing', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 8),
      Text('${session.accurateCount} of ${TimeSenseSession.roundCount} estimates were close',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      const Text('Three close estimates pass the level.',
        textAlign: TextAlign.center, style: TextStyle(color: _muted)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
        label: const Text('PLAY AGAIN')),
    ],
  ));
}

const _paper = Color(0xFFFFF7F1);
const _ink = Color(0xFF59433B);
const _muted = Color(0xFF99837A);
const _coral = Color(0xFFD99D86);
const _mint = Color(0xFF73AD98);
