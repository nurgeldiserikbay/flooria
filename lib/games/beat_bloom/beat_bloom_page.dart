import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'beat_bloom_engine.dart';

class BeatBloomPage extends StatefulWidget {
  const BeatBloomPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctRounds, int offBeatTaps) onSessionEnd;

  @override
  State<BeatBloomPage> createState() => _BeatBloomPageState();
}

class _BeatBloomPageState extends State<BeatBloomPage>
    with SingleTickerProviderStateMixin {
  late BeatBloomSession game;
  late final AnimationController _pulse;
  final Stopwatch _clock = Stopwatch();
  int _attempt = 0;
  String _message = 'Tap when the bloom reaches its largest size';
  Duration get _pulseHalfBeat =>
      Duration(milliseconds: game.currentIntervalMillis ~/ 2);

  @override
  void initState() {
    super.initState();
    _resetSession();
    _pulse = AnimationController(
      vsync: this,
      duration: _pulseHalfBeat,
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
    _clock.start();
  }

  void _resetSession() {
    game = BeatBloomSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _attempt
          : widget.floor! * 719 + _attempt,
    );
    _clock
      ..reset()
      ..start();
    _message = 'Tap when the bloom reaches its largest size';
  }

  void _tap() {
    if (game.finished || game.roundComplete) return;
    final isLastRound = game.round == BeatBloomSession.roundCount - 1;
    final result = game.tapAt(_clock.elapsedMilliseconds);
    if (result == BeatBloomTapResult.invalid) return;

    setState(() {
      if (result == BeatBloomTapResult.roundComplete) {
        _pulse.stop();
        _message = game.lastRoundAccurate
            ? 'Lovely rhythm! ${game.onBeatTaps} of 6 beats landed.'
            : 'Keep the rhythm. ${game.onBeatTaps} of 6 beats landed.';
      } else {
        _message = result == BeatBloomTapResult.onBeat
            ? 'On the beat!'
            : 'A little early or late — keep going.';
      }
    });
    if (result == BeatBloomTapResult.roundComplete && isLastRound) {
      _finishSession();
    }
  }

  void _advance() {
    if (!game.advance()) return;
    setState(() {
      _pulse
        ..duration = _pulseHalfBeat
        ..repeat(reverse: true);
      _clock
        ..reset()
        ..start();
      _message = 'New tempo — follow the bloom';
    });
  }

  void _finishSession() {
    _clock.stop();
    widget.onSessionEnd(game.correctRounds, game.offBeatTaps);
    if (widget.floor != null && game.passed) widget.onComplete();
  }

  void _playAgain() {
    setState(() {
      _attempt++;
      _resetSession();
      _pulse
        ..duration = _pulseHalfBeat
        ..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _clock.stop();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3D526E);
    const lavender = Color(0xFF857BCB);
    final isComplete = game.roundComplete;
    final isFinished = game.finished;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF8F6FF),
        foregroundColor: ink,
        title: const Text('Beat Bloom',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8588A8))),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE6F5F1),
                    Color(0xFFF0ECFF),
                    Color(0xFFFFF0E3),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.spa_rounded,
                          color: Color(0xFF62A995), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Match the flower’s steady pulse',
                            style: TextStyle(
                                color: ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ),
                      Text(
                          '${game.correctRounds} / ${BeatBloomSession.roundCount}',
                          style: const TextStyle(
                              color: Color(0xFF7276A4),
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFinished
                        ? (game.passed ? 'A beautiful rhythm!' : 'Keep practicing')
                        : 'RHYTHM ${game.round + 1}  ·  ${game.currentIntervalMillis} ms',
                    style: const TextStyle(
                        color: Color(0xFF777DA2),
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final side = math.min(bounds.maxWidth, bounds.maxHeight);
                        return Center(
                          child: SizedBox(
                            width: side,
                            height: side,
                            child: Material(
                              color: const Color(0xDFFFFFFF),
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: const ValueKey('beat-bloom-target'),
                                customBorder: const CircleBorder(),
                                onTap: isComplete || isFinished ? null : _tap,
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _pulse,
                                    builder: (context, child) {
                                      final scale = 0.72 + _pulse.value * 0.28;
                                      return Transform.scale(
                                        scale: scale,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      width: side * 0.68,
                                      height: side * 0.68,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFE2F4E9),
                                        border: Border.all(
                                            color: const Color(0xFFB8E2D0),
                                            width: 3),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x3378B9A1),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.local_florist_rounded,
                                        size: side * 0.40,
                                        color: const Color(0xFF79BCA3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      BeatBloomSession.tapsPerRound,
                      (index) => Container(
                        key: ValueKey('beat-dot-$index'),
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < game.tapCount
                              ? (game.tapAccuracy[index]
                                  ? const Color(0xFF72B69C)
                                  : const Color(0xFFE8A59D))
                              : const Color(0xFFD9D9E8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: Text(
                        isFinished
                            ? '${game.correctRounds} rhythms accurate · ${game.offBeatTaps} off-beat taps'
                            : _message,
                        key: const ValueKey('beat-bloom-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('beat-bloom-action'),
                      onPressed: isFinished
                          ? _playAgain
                          : isComplete
                              ? _advance
                              : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: lavender,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB6B2CF),
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Text(
                        isFinished
                            ? 'PLAY AGAIN'
                            : isComplete
                                ? 'NEXT RHYTHM'
                                : '${game.tapCount} / ${BeatBloomSession.tapsPerRound} TAPS',
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
