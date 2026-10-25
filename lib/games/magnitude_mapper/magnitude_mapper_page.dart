import 'package:flutter/material.dart';

import 'magnitude_mapper_engine.dart';

class MagnitudeMapperPage extends StatefulWidget {
  const MagnitudeMapperPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int accuratePlacements, int mistakes) onSessionEnd;

  @override
  State<MagnitudeMapperPage> createState() => _MagnitudeMapperPageState();
}

class _MagnitudeMapperPageState extends State<MagnitudeMapperPage> {
  late MagnitudeMapperSession session;
  int _revision = 0;
  bool _inputLocked = false;
  bool _reported = false;
  String? _feedback;
  bool? _lastAnswerWasAccurate;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _inputLocked = false;
    _reported = false;
    _feedback = null;
    _lastAnswerWasAccurate = null;
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = MagnitudeMapperSession(seed: seed, level: level);
  }

  void _setGuess(double value) {
    if (_inputLocked) return;
    setState(() => session.setGuess(value));
  }

  void _submit() {
    if (_inputLocked || session.finished) return;
    _inputLocked = true;
    final wasAccurate = session.current.isAccurate(session.guessPosition);
    final result = session.submit();
    if (result == MagnitudeSubmitResult.invalid) {
      _inputLocked = false;
      return;
    }

    setState(() {
      _lastAnswerWasAccurate = wasAccurate;
      _feedback = wasAccurate
          ? 'Nicely placed!'
          : 'The target was outside your estimate band.';
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.accurateCount, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _inputLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final round = session.current;
    final estimate = (round.minimum +
            session.guessPosition * (round.maximum - round.minimum))
        .round();

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Magnitude Mapper',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${session.mistakes} misses',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'Number line complete'
                          : 'Number ${session.roundIndex + 1} of '
                              '${MagnitudeMapperSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE6EEF0),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: complete
                        ? _MagnitudeResults(
                            correct: session.accurateCount,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _softMint,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'PLACE THE NUMBER',
                                      style: TextStyle(
                                        color: _deepTeal,
                                        letterSpacing: .9,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Drag the marker to your best estimate.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _ink,
                                        fontSize: 13,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFEFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _edge),
                                  ),
                                  child: Column(
                                    children: [
                                      const Spacer(),
                                      const Text(
                                        'FIND THIS VALUE',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        round.target.toString(),
                                        style: const TextStyle(
                                          color: _ink,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _softMint,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Your estimate: $estimate',
                                          style: const TextStyle(
                                            color: _deepTeal,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: _teal,
                                          inactiveTrackColor: _track,
                                          thumbColor: _deepTeal,
                                          overlayColor:
                                              _teal.withValues(alpha: .12),
                                          trackHeight: 7,
                                        ),
                                        child: Slider(
                                          key: const ValueKey(
                                              'magnitude-slider'),
                                          value: session.guessPosition,
                                          min: 0,
                                          max: 1,
                                          divisions: 200,
                                          label: estimate.toString(),
                                          onChanged: _inputLocked
                                              ? null
                                              : _setGuess,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            round.minimum.toString(),
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            (round.maximum ~/ 2).toString(),
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            round.maximum.toString(),
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton.icon(
                                  key: const ValueKey('magnitude-submit'),
                                  onPressed: _inputLocked ? null : _submit,
                                  icon: const Icon(Icons.push_pin_rounded),
                                  label: const Text('CHECK PLACEMENT'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 19,
                                child: Center(
                                  child: Text(
                                    _feedback ?? 'Precision matters more on higher floors.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _lastAnswerWasAccurate == false
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

class _MagnitudeResults extends StatelessWidget {
  const _MagnitudeResults({
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
              passed ? Icons.straighten_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Great sense of scale!' : 'Try the number line again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct accurate placements · $mistakes misses',
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
                backgroundColor: _teal,
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

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8D9892);
const _teal = Color(0xFF5D9E88);
const _deepTeal = Color(0xFF4C8272);
const _softMint = Color(0xFFE5F2EA);
const _track = Color(0xFFD8E7DE);
const _edge = Color(0xFFE8EEE9);
const _coral = Color(0xFFC97D72);
