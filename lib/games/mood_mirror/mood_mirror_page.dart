import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mood_mirror_engine.dart';

class MoodMirrorPage extends StatefulWidget {
  const MoodMirrorPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<MoodMirrorPage> createState() => _MoodMirrorPageState();
}

class _MoodMirrorPageState extends State<MoodMirrorPage> {
  late MoodMirrorSession session;
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
    session = MoodMirrorSession(seed: seed, level: level);
  }

  void _answer(FacialEmotion emotion) {
    if (_inputLocked || session.finished) return;
    _inputLocked = true;
    final wasCorrect = emotion == session.current.emotion;
    final result = session.respond(emotion);

    if (result == MoodResponseResult.invalid) {
      _inputLocked = false;
      return;
    }

    setState(() {
      _lastAnswerWasCorrect = wasCorrect;
      _feedback = wasCorrect
          ? 'Good read!'
          : 'Look at the eyes, brows and mouth.';
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
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
                          'Mood Mirror',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
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
                          ? 'Reading complete'
                          : 'Face ${session.roundIndex + 1} of '
                              '${MoodMirrorSession.roundCount}',
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
                      backgroundColor: const Color(0xFFF0EAF0),
                      color: _plum,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: complete
                        ? _MoodResults(
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
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _softRose,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'READ THE EXPRESSION',
                                      style: TextStyle(
                                        color: _deepPlum,
                                        letterSpacing: .9,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'How might this person be feeling?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 7),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFEFB),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _edge),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final diameter = math.min(
                                        constraints.maxWidth - 24,
                                        constraints.maxHeight - 16,
                                      ).clamp(0.0, 230.0);
                                      return Center(
                                        child: CustomPaint(
                                          size: Size.square(diameter),
                                          painter: _ExpressionPainter(
                                            emotion: round.emotion,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Expanded(
                                flex: 2,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const columns = 2;
                                    const gap = 7.0;
                                    final rows =
                                        (round.choices.length / columns).ceil();
                                    final tileWidth =
                                        (constraints.maxWidth - gap) / columns;
                                    final tileHeight =
                                        (constraints.maxHeight -
                                            gap * (rows - 1)) /
                                        rows;
                                    return GridView.builder(
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: round.choices.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: gap,
                                        mainAxisSpacing: gap,
                                        childAspectRatio: tileWidth /
                                            math.max(1.0, tileHeight),
                                      ),
                                      itemBuilder: (context, index) =>
                                          _MoodChoice(
                                        key: ValueKey('mood-choice-$index'),
                                        emotion: round.choices[index],
                                        enabled: !_inputLocked,
                                        onTap: () => _answer(round.choices[index]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 19,
                                child: Center(
                                  child: Text(
                                    _feedback ?? 'Choose the closest feeling.',
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

class _ExpressionPainter extends CustomPainter {
  const _ExpressionPainter({required this.emotion});

  final FacialEmotion emotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .42;
    final facePaint = Paint()..color = const Color(0xFFFFD6AE);
    final shadowPaint = Paint()..color = const Color(0x1A73564A);
    canvas.drawCircle(center.translate(0, 3), radius, shadowPaint);
    canvas.drawCircle(center, radius, facePaint);

    final featurePaint = Paint()
      ..color = _faceInk
      ..strokeWidth = radius * .055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eyeFill = Paint()
      ..color = _faceInk
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - radius * .13;
    final leftEye = Offset(center.dx - radius * .37, eyeY);
    final rightEye = Offset(center.dx + radius * .37, eyeY);
    final eyeRadius = radius * (emotion == FacialEmotion.surprise ? .075 : .055);

    if (emotion == FacialEmotion.calm) {
      for (final eye in [leftEye, rightEye]) {
        final path = Path()
          ..moveTo(eye.dx - radius * .13, eye.dy)
          ..quadraticBezierTo(
            eye.dx,
            eye.dy + radius * .10,
            eye.dx + radius * .13,
            eye.dy,
          );
        canvas.drawPath(path, featurePaint);
      }
    } else {
      canvas.drawCircle(leftEye, eyeRadius, eyeFill);
      canvas.drawCircle(rightEye, eyeRadius, eyeFill);
    }

    _drawBrows(canvas, center, radius, eyeY, featurePaint);
    _drawMouth(canvas, center, radius, featurePaint, eyeFill);
  }

  void _drawBrows(
    Canvas canvas,
    Offset center,
    double radius,
    double eyeY,
    Paint paint,
  ) {
    final leftStart = Offset(center.dx - radius * .52, eyeY - radius * .24);
    final leftEnd = Offset(center.dx - radius * .22, eyeY - radius * .24);
    final rightStart = Offset(center.dx + radius * .22, eyeY - radius * .24);
    final rightEnd = Offset(center.dx + radius * .52, eyeY - radius * .24);
    final leftPath = Path()..moveTo(leftStart.dx, leftStart.dy);
    final rightPath = Path()..moveTo(rightStart.dx, rightStart.dy);

    switch (emotion) {
      case FacialEmotion.anger:
        leftPath.lineTo(leftEnd.dx, leftEnd.dy + radius * .13);
        rightPath.lineTo(rightEnd.dx, rightEnd.dy + radius * .13);
      case FacialEmotion.sadness:
      case FacialEmotion.worry:
        leftPath.lineTo(leftEnd.dx, leftEnd.dy + radius * .11);
        rightPath.lineTo(rightEnd.dx, rightEnd.dy - radius * .02);
      case FacialEmotion.surprise:
        leftPath.quadraticBezierTo(
          center.dx - radius * .36,
          leftStart.dy - radius * .13,
          leftEnd.dx,
          leftEnd.dy,
        );
        rightPath.quadraticBezierTo(
          center.dx + radius * .36,
          rightStart.dy - radius * .13,
          rightEnd.dx,
          rightEnd.dy,
        );
      case FacialEmotion.joy:
      case FacialEmotion.calm:
        leftPath.quadraticBezierTo(
          center.dx - radius * .37,
          leftStart.dy - radius * .05,
          leftEnd.dx,
          leftEnd.dy,
        );
        rightPath.quadraticBezierTo(
          center.dx + radius * .37,
          rightStart.dy - radius * .05,
          rightEnd.dx,
          rightEnd.dy,
        );
    }

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
  }

  void _drawMouth(
    Canvas canvas,
    Offset center,
    double radius,
    Paint stroke,
    Paint fill,
  ) {
    final mouthY = center.dy + radius * .34;
    final mouthWidth = radius * .44;

    if (emotion == FacialEmotion.surprise) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: radius * .25,
          height: radius * .37,
        ),
        fill,
      );
      return;
    }

    final path = Path()..moveTo(center.dx - mouthWidth, mouthY);
    switch (emotion) {
      case FacialEmotion.joy:
        path.quadraticBezierTo(
          center.dx,
          mouthY + radius * .46,
          center.dx + mouthWidth,
          mouthY,
        );
      case FacialEmotion.sadness:
      case FacialEmotion.anger:
        path.quadraticBezierTo(
          center.dx,
          mouthY - radius * .34,
          center.dx + mouthWidth,
          mouthY,
        );
      case FacialEmotion.worry:
        path.quadraticBezierTo(
          center.dx,
          mouthY - radius * .20,
          center.dx + mouthWidth,
          mouthY + radius * .03,
        );
      case FacialEmotion.calm:
        path.quadraticBezierTo(
          center.dx,
          mouthY + radius * .16,
          center.dx + mouthWidth,
          mouthY,
        );
      case FacialEmotion.surprise:
        break;
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ExpressionPainter oldDelegate) =>
      oldDelegate.emotion != emotion;
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    super.key,
    required this.emotion,
    required this.enabled,
    required this.onTap,
  });

  final FacialEmotion emotion;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: enabled,
        label: emotion.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _edge, width: 1.4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x102B2430),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                emotion.label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
}

class _MoodResults extends StatelessWidget {
  const _MoodResults({
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
              passed ? Icons.favorite_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _plum : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Thoughtful observer!' : 'Try reading the cues again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct expressions read · $mistakes misses',
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
                backgroundColor: _plum,
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

extension on FacialEmotion {
  String get label => switch (this) {
        FacialEmotion.joy => 'Joy',
        FacialEmotion.sadness => 'Sadness',
        FacialEmotion.anger => 'Anger',
        FacialEmotion.surprise => 'Surprise',
        FacialEmotion.calm => 'Calm',
        FacialEmotion.worry => 'Worry',
      };
}

const _paper = Color(0xFFFCFAF8);
const _ink = Color(0xFF514951);
const _muted = Color(0xFF958A92);
const _plum = Color(0xFFB07F9D);
const _deepPlum = Color(0xFF91647F);
const _softRose = Color(0xFFF6EAF0);
const _edge = Color(0xFFEFE7EA);
const _faceInk = Color(0xFF614B48);
const _coral = Color(0xFFC97D72);
