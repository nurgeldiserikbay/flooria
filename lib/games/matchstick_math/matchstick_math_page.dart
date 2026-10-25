import 'package:flutter/material.dart';
import 'matchstick_math_engine.dart';

class MatchstickMathPage extends StatefulWidget {
  const MatchstickMathPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correctAnswers, int mistakes) onSessionEnd;

  @override
  State<MatchstickMathPage> createState() => _MatchstickMathPageState();
}

class _MatchstickMathPageState extends State<MatchstickMathPage> {
  late MatchstickMathSession session;
  int _revision = 0;
  int? _wrongChoice;
  bool _reported = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _wrongChoice = null;
    _feedback = null;
    session = MatchstickMathSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 104729 + _revision++,
    );
  }

  void _choose(int index) {
    final result = session.choose(index);
    if (result == MatchstickPickResult.invalid) return;

    if (result == MatchstickPickResult.incorrect) {
      setState(() {
        _wrongChoice = index;
        _feedback = 'That move does not make a true equation. Try again.';
      });
      return;
    }

    setState(() {
      _wrongChoice = null;
      _feedback = result == MatchstickPickResult.complete
          ? null
          : 'Correct move. Find the next equation!';
    });

    if (result == MatchstickPickResult.complete && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctAnswers, session.mistakes);
      if (widget.floor != null) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final puzzle = session.current;

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
                    child: Text('Matchstick Math', style: TextStyle(
                      color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      complete
                          ? 'All 5 equations fixed'
                          : 'Puzzle ${session.roundIndex + 1} of ${MatchstickMathSession.roundCount}',
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
                      backgroundColor: const Color(0xFFF0E7D8),
                      color: _orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _MatchResults(
                            correct: session.correctAnswers,
                            mistakes: session.mistakes,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _softGold,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white, width: 3,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'ONE MATCHSTICK MOVE',
                                      style: TextStyle(
                                        color: _brown, letterSpacing: 1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Which move makes this equation true?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _ink, fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${session.mistakes} slips',
                                      style: const TextStyle(
                                        color: _muted, fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFCF7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _edge),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var index = 0;
                                        index < puzzle.equation.glyphs.length;
                                        index++) ...[
                                      if (index > 0)
                                        const SizedBox(width: 5),
                                      _MatchGlyph(
                                        glyph: puzzle.equation.glyphs[index],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    for (var index = 0;
                                        index < puzzle.choices.length;
                                        index++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            bottom:
                                                index == puzzle.choices.length - 1
                                                    ? 0 : 7,
                                          ),
                                          child: _MoveOption(
                                            key: ValueKey(
                                              'matchstick-move-$index',
                                            ),
                                            index: index,
                                            equation: puzzle.equation,
                                            move: puzzle.choices[index],
                                            selectedWrong:
                                                index == _wrongChoice,
                                            onTap: () => _choose(index),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 22,
                                child: Center(
                                  child: Text(
                                    _feedback ?? 'Only one match may move.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _wrongChoice != null
                                          ? _coral : _muted,
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

class _MatchGlyph extends StatelessWidget {
  const _MatchGlyph({required this.glyph});
  final String glyph;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 66,
    child: CustomPaint(
      painter: _GlyphPainter(
        glyph: glyph,
        lit: MatchstickGlyph.segmentsFor(glyph),
      ),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.glyph, required this.lit});
  final String glyph;
  final Set<int> lit;

  @override
  void paint(Canvas canvas, Size size) {
    final rects = _rectangles(glyph, size);
    for (final entry in rects.entries) {
      final isLit = lit.contains(entry.key);
      final paint = Paint()
        ..color = isLit ? _match : _unlit
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, const Radius.circular(3)),
        paint,
      );
      if (isLit) {
        final shine = Paint()..color = const Color(0x55FFFFFF);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            entry.value.deflate(2),
            const Radius.circular(2),
          ),
          shine,
        );
      }
    }
  }

  Map<int, Rect> _rectangles(String value, Size size) {
    final w = size.width;
    final h = size.height;
    const thickness = 6.0;
    final standard = <int, Rect>{
      0: Rect.fromLTWH(8, 1, w - 16, thickness),
      1: Rect.fromLTWH(w - thickness - 1, 6, thickness, h / 2 - 9),
      2: Rect.fromLTWH(w - thickness - 1, h / 2 + 3, thickness, h / 2 - 9),
      3: Rect.fromLTWH(8, h - thickness - 1, w - 16, thickness),
      4: Rect.fromLTWH(1, h / 2 + 3, thickness, h / 2 - 9),
      5: Rect.fromLTWH(1, 6, thickness, h / 2 - 9),
      6: Rect.fromLTWH(8, h / 2 - thickness / 2, w - 16, thickness),
      7: Rect.fromLTWH(w / 2 - thickness / 2, 9, thickness, h / 2 - 11),
      8: Rect.fromLTWH(w / 2 - thickness / 2, h / 2 + 2, thickness, h / 2 - 11),
    };
    if (value == '+') {
      return {6: standard[6]!, 7: standard[7]!, 8: standard[8]!};
    }
    if (value == '-') return {6: standard[6]!};
    if (value == '=') {
      return {
        0: Rect.fromLTWH(6, h / 2 - 10, w - 12, thickness),
        3: Rect.fromLTWH(6, h / 2 + 4, w - 12, thickness),
      };
    }
    return {for (var segment = 0; segment < 7; segment++) segment: standard[segment]!};
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.lit.length != lit.length;
}

class _MoveOption extends StatelessWidget {
  const _MoveOption({
    super.key,
    required this.index,
    required this.equation,
    required this.move,
    required this.selectedWrong,
    required this.onTap,
  });

  final int index;
  final MatchstickEquation equation;
  final MatchstickMove move;
  final bool selectedWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fromName = equation.glyphs[move.fromGlyph];
    final toName = equation.glyphs[move.toGlyph];
    final description =
        'Move ${MatchstickGlyph.segmentName(move.fromSegment)} from $fromName '
        'to ${MatchstickGlyph.segmentName(move.toSegment)} on $toName';

    return Semantics(
      button: true,
      label: description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selectedWrong ? _wrongFill : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedWrong ? _coral : _edge,
                width: selectedWrong ? 2 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x142C302D),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _softGold,
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      color: _brown, fontSize: 11, fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink, fontSize: 12, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.swap_horiz_rounded,
                  color: _orange, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchResults extends StatelessWidget {
  const _MatchResults({
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
        const Icon(Icons.rule_rounded, size: 62, color: _orange),
        const SizedBox(height: 10),
        const Text('Equation expert!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink, fontSize: 22, fontWeight: FontWeight.w900,
          )),
        const SizedBox(height: 8),
        Text('$correct equations fixed · $mistakes slips',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('PLAY AGAIN'),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ),
  );
}

const _paper = Color(0xFFFCFAF6);
const _ink = Color(0xFF554D42);
const _muted = Color(0xFF999083);
const _orange = Color(0xFFD49A57);
const _softGold = Color(0xFFF7EBD8);
const _brown = Color(0xFF967247);
const _match = Color(0xFFE1A84B);
const _unlit = Color(0xFFECE8E1);
const _edge = Color(0xFFEDE7DD);
const _wrongFill = Color(0xFFFFF0EC);
const _coral = Color(0xFFC47B70);
