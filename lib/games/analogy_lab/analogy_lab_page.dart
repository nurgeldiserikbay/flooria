import 'package:flutter/material.dart';

import 'analogy_lab_engine.dart';

class AnalogyLabPage extends StatefulWidget {
  const AnalogyLabPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<AnalogyLabPage> createState() => _AnalogyLabPageState();
}

class _AnalogyLabPageState extends State<AnalogyLabPage> {
  late AnalogyLabSession session;
  int _displayIndex = 0;
  int _revision = 0;
  int? _selectedIndex;
  bool? _lastWasCorrect;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _displayIndex = 0;
    _selectedIndex = null;
    _lastWasCorrect = null;
    _reported = false;
    final floor = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 104729 + _revision;
    _revision++;
    session = AnalogyLabSession(seed: seed, level: floor);
  }

  void _choose(int index) {
    if (_selectedIndex != null || session.finished) return;
    final round = session.current;
    final result = session.submit(index);
    if (result == AnalogySubmitResult.invalid) return;

    setState(() {
      _selectedIndex = index;
      _lastWasCorrect = index == round.correctIndex;
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.correctCount, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }
  }

  void _next() {
    if (_selectedIndex == null || session.finished) return;
    setState(() {
      _displayIndex = session.roundIndex;
      _selectedIndex = null;
      _lastWasCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final round = session.rounds[_displayIndex];

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
                          'Analogy Lab',
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
                          ? 'Reasoning complete'
                          : 'Analogy ${_displayIndex + 1} of '
                              '${AnalogyLabSession.roundCount}',
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
                        ? _AnalogyResults(
                            correct: session.correctCount,
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
                                child: const Text(
                                  'Study the change, then apply the same rule.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFEFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _edge),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'SAME RULE',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .9,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _AnalogyTile(
                                                label: 'EXAMPLE',
                                                token: round.exampleFrom,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                color: _teal,
                                                size: 22,
                                              ),
                                            ),
                                            Expanded(
                                              child: _AnalogyTile(
                                                label: 'BECOMES',
                                                token: round.exampleTo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Divider(height: 1),
                                      const SizedBox(height: 7),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _AnalogyTile(
                                                label: 'NOW',
                                                token: round.prompt,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                color: _teal,
                                                size: 22,
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _softMint,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFD5E9DC,
                                                    ),
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    '?',
                                                    style: TextStyle(
                                                      color: _deepTeal,
                                                      fontSize: 37,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
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
                              const SizedBox(height: 8),
                              if (_selectedIndex == null)
                                _AnswerOptions(round: round, onChoose: _choose)
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton.icon(
                                    key: const ValueKey('analogy-next'),
                                    onPressed: _next,
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    label: const Text('NEXT ANALOGY'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 20,
                                child: Center(
                                  child: Text(
                                    _lastWasCorrect == null
                                        ? 'Look for changes in shape, color, or count.'
                                        : _lastWasCorrect!
                                            ? 'Correct — you found the rule.'
                                            : 'Not quite. Study how the example changed.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _lastWasCorrect == false
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

class _AnswerOptions extends StatelessWidget {
  const _AnswerOptions({required this.round, required this.onChoose});

  final AnalogyRound round;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 132,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: round.options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) => Material(
            color: const Color(0xFFFFFEFC),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              key: ValueKey('analogy-option-$index'),
              borderRadius: BorderRadius.circular(15),
              onTap: () => onChoose(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _edge, width: 1.5),
                ),
                child: Center(
                  child: _TokenArt(token: round.options[index], size: 21),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AnalogyTile extends StatelessWidget {
  const _AnalogyTile({required this.label, required this.token});

  final String label;
  final AnalogyToken token;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _edge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 7),
            _TokenArt(token: token, size: 25),
          ],
        ),
      );
}

class _TokenArt extends StatelessWidget {
  const _TokenArt({required this.token, required this.size});

  final AnalogyToken token;
  final double size;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 1,
        children: [
          for (var index = 0; index < token.count; index++)
            Icon(
              switch (token.shape) {
                AnalogyShape.circle => Icons.circle,
                AnalogyShape.square => Icons.square_rounded,
                AnalogyShape.triangle => Icons.change_history_rounded,
                AnalogyShape.diamond => Icons.diamond_rounded,
              },
              color: switch (token.color) {
                AnalogyColor.coral => _coral,
                AnalogyColor.blue => const Color(0xFF78A6CF),
                AnalogyColor.amber => const Color(0xFFD8AE61),
                AnalogyColor.mint => const Color(0xFF70AB91),
              },
              size: size,
            ),
        ],
      );
}

class _AnalogyResults extends StatelessWidget {
  const _AnalogyResults({
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
              passed ? Icons.lightbulb_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Rule spotted!' : 'Keep looking for the pattern',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
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
const _edge = Color(0xFFE8EEE9);
const _coral = Color(0xFFC97D72);
