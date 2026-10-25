import 'package:flutter/material.dart';

import 'mind_loop_engine.dart';

class MindLoopPage extends StatefulWidget {
  const MindLoopPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<MindLoopPage> createState() => _MindLoopPageState();
}

class _MindLoopPageState extends State<MindLoopPage> {
  late MindLoopSession session;
  int _revision = 0;
  bool _inputLocked = false;
  bool _reported = false;
  String? _feedback;
  bool? _lastAnswerWasCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _inputLocked = false;
    _reported = false;
    _feedback = null;
    _lastAnswerWasCorrect = null;
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = MindLoopSession(seed: seed, level: level);
  }

  void _answer(bool saysMatch) {
    if (_inputLocked || session.finished) return;
    _inputLocked = true;

    final wasCorrect = saysMatch == session.currentIsMatch;
    final result = session.respond(saysMatch);
    if (result == LoopResponseResult.invalid) {
      _inputLocked = false;
      return;
    }

    setState(() {
      _lastAnswerWasCorrect = wasCorrect;
      _feedback = wasCorrect ? 'Nice recall!' : 'Keep tracking the sequence.';
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (session.passed) widget.onComplete();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _inputLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final backLabel = session.backSteps == 2 ? 'TWO BACK' : 'THREE BACK';

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mind Loop',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _softLavender,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          backLabel,
                          style: const TextStyle(
                            color: _deepPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'Sequence complete'
                          : 'Trial ${session.trialIndex + 1} of ${MindLoopSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFECE8F0),
                      color: _purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: complete
                        ? _MindLoopResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _softLavender,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      session.trialIndex < session.backSteps
                                          ? 'BUILD YOUR SEQUENCE'
                                          : 'COMPARE WITH ${session.backSteps} '
                                              'TURNS AGO',
                                      style: const TextStyle(
                                        color: _deepPurple,
                                        letterSpacing: .8,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      session.trialIndex < session.backSteps
                                          ? 'Remember each symbol as it appears.'
                                          : 'Does this symbol match the earlier one?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFDFF),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: _edge),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        session.currentSymbol.icon,
                                        size: 86,
                                        color: session.currentSymbol.color,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${session.correctAnswers} correct'
                                        '  ·  ${session.mistakes} misses',
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AnswerButton(
                                      key: const ValueKey('mind-answer-match'),
                                      label: 'MATCH',
                                      icon: Icons.check_circle_rounded,
                                      color: _teal,
                                      enabled: !_inputLocked,
                                      onTap: () => _answer(true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _AnswerButton(
                                      key: const ValueKey('mind-answer-new'),
                                      label: 'NEW',
                                      icon: Icons.circle_outlined,
                                      color: _blue,
                                      enabled: !_inputLocked,
                                      onTap: () => _answer(false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _feedback ?? 'Choose MATCH or NEW.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _lastAnswerWasCorrect == false
                                          ? _coral
                                          : _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF8F6F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.65 : 0.25),
                width: 1.7,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x102B2530),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MindLoopResults extends StatelessWidget {
  const _MindLoopResults({
    required this.correct,
    required this.mistakes,
    required this.passed,
    required this.onRetry,
  });

  final int correct;
  final int mistakes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.psychology_alt_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _purple : _blue,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Loop mastered!' : 'Try the sequence again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct correct · $mistakes misses',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
}

extension on LoopSymbol {
  IconData get icon => switch (this) {
        LoopSymbol.circle => Icons.circle_rounded,
        LoopSymbol.square => Icons.square_rounded,
        LoopSymbol.triangle => Icons.change_history_rounded,
        LoopSymbol.diamond => Icons.diamond_rounded,
        LoopSymbol.star => Icons.star_rounded,
      };

  Color get color => switch (this) {
        LoopSymbol.circle => const Color(0xFF67AE97),
        LoopSymbol.square => const Color(0xFF7B9DD0),
        LoopSymbol.triangle => const Color(0xFFE7B65C),
        LoopSymbol.diamond => const Color(0xFFDC8E84),
        LoopSymbol.star => const Color(0xFF9B88C3),
      };
}

const _paper = Color(0xFFFBF9FC);
const _ink = Color(0xFF4B4650);
const _muted = Color(0xFF928B98);
const _purple = Color(0xFF9B88C3);
const _deepPurple = Color(0xFF7968A4);
const _softLavender = Color(0xFFF0EBF8);
const _edge = Color(0xFFEAE5EE);
const _teal = Color(0xFF5D9F89);
const _blue = Color(0xFF688DBB);
const _coral = Color(0xFFC87A70);
