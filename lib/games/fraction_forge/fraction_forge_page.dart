import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fraction_forge_engine.dart';

class FractionForgePage extends StatefulWidget {
  const FractionForgePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<FractionForgePage> createState() => _FractionForgePageState();
}

class _FractionForgePageState extends State<FractionForgePage> {
  late FractionForgeSession session;
  int _revision = 0;
  bool _reported = false;
  int? _wrongOption;
  bool _lastWasCorrect = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _wrongOption = null;
    _lastWasCorrect = false;
    session = FractionForgeSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 65537 + _revision++,
    );
  }

  void _choose(int index) {
    final result = session.choose(index);
    if (result == FractionPickResult.invalid) return;
    setState(() {
      _wrongOption = result == FractionPickResult.incorrect ? index : null;
      _lastWasCorrect = result == FractionPickResult.correct ||
          result == FractionPickResult.complete;
    });
    if (result == FractionPickResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final challenge = session.current;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Fraction Forge', style: TextStyle(
                      color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'Session complete'
                          : 'Question ${session.roundIndex + 1} of ${FractionForgeSession.roundCount}',
                      style: const TextStyle(
                        color: _muted, fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE6EDE5),
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _FractionResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _softGreen,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white, width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'REFERENCE POINT',
                                      style: TextStyle(
                                        color: _green, letterSpacing: 1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Choose the fraction closest to ${challenge.target.label}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _ink, fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    _FractionBar(
                                      value: challenge.target.value,
                                      color: _green,
                                    ),
                                    const SizedBox(height: 3),
                                    Text('${session.mistakes} slips',
                                      style: const TextStyle(
                                        color: _muted, fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final side = math.min(
                                        box.maxWidth, box.maxHeight,
                                      );
                                      return SizedBox(
                                        width: box.maxWidth,
                                        height: box.maxHeight,
                                        child: GridView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: challenge.options.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.12,
                                          ),
                                          itemBuilder: (context, index) {
                                            final fraction =
                                                challenge.options[index];
                                            final wrong = index == _wrongOption;
                                            return _FractionOption(
                                              key: ValueKey(
                                                'fraction-forge-option-$index',
                                              ),
                                              fraction: fraction,
                                              wrong: wrong,
                                              onTap: () => _choose(index),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _wrongOption != null
                                        ? 'Try again — compare the bar lengths.'
                                        : _lastWasCorrect
                                            ? 'Exactly right. Keep going!'
                                            : 'Compare each bar with the reference.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _wrongOption != null
                                          ? _coral
                                          : _lastWasCorrect
                                              ? _green
                                              : _muted,
                                      fontSize: 12,
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

class _FractionOption extends StatelessWidget {
  const _FractionOption({
    super.key,
    required this.fraction,
    required this.wrong,
    required this.onTap,
  });

  final FractionValue fraction;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Fraction ${fraction.label}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: wrong ? _wrongFill : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: wrong ? _coral : _edge, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142C4938),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(fraction.label, style: const TextStyle(
                color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 9),
              _FractionBar(value: fraction.value, color: _orange),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FractionBar extends StatelessWidget {
  const _FractionBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 12,
      decoration: const BoxDecoration(color: Color(0xFFEFF2EC)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _FractionResults extends StatelessWidget {
  const _FractionResults({
    required this.correct,
    required this.mistakes,
    required this.onRetry,
  });
  final int correct;
  final int mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pie_chart_rounded, size: 62, color: _green),
        const SizedBox(height: 10),
        const Text('Fractions mastered!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink, fontSize: 23, fontWeight: FontWeight.w900,
          )),
        const SizedBox(height: 8),
        Text('$correct correct · $mistakes slips',
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('PLAY AGAIN'),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ),
  );
}

const _paper = Color(0xFFF9FBF8);
const _ink = Color(0xFF47574B);
const _muted = Color(0xFF87958A);
const _green = Color(0xFF79A884);
const _softGreen = Color(0xFFE7F1E8);
const _orange = Color(0xFFE8B468);
const _edge = Color(0xFFE5EBE3);
const _wrongFill = Color(0xFFFFF0EC);
const _coral = Color(0xFFC77F70);
