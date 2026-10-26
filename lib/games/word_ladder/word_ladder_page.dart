import 'package:flutter/material.dart';

import 'word_ladder_engine.dart';

class WordLadderPage extends StatefulWidget {
  const WordLadderPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int solved, int mistakes) onSessionEnd;

  @override
  State<WordLadderPage> createState() => _WordLadderPageState();
}

class _WordLadderPageState extends State<WordLadderPage> {
  late WordLadderSession session;
  int _revision = 0;
  bool _awaitingContinue = false;
  bool _reported = false;
  String? _feedback;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final level = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 130363 + _revision;
    _revision++;
    session = WordLadderSession(seed: seed, level: level);
    _awaitingContinue = false;
    _reported = false;
    _feedback = null;
    _lastCorrect = null;
  }

  void _answer(String word) {
    if (_awaitingContinue || session.finished) return;
    final prompt = session.prompt;
    final result = session.answer(word);
    if (result == WordLadderAnswer.invalid) return;

    setState(() {
      _awaitingContinue = !session.finished;
      _lastCorrect = word == prompt.correctWord;
      _feedback = _lastCorrect!
          ? prompt.rung == prompt.rungCount
              ? 'Ladder complete — nice word work!'
              : 'That word fits. Keep climbing.'
          : 'Dead end. Try the next ladder.';
    });

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(session.solved, session.mistakes);
      if (widget.floor != null && session.passed) widget.onComplete();
    }
  }

  void _continue() {
    if (!_awaitingContinue) return;
    setState(() {
      _awaitingContinue = false;
      _feedback = null;
      _lastCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Word Ladder',
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
                      finished
                          ? 'Ladders complete'
                          : 'Ladder ${(session.roundIndex + 1).clamp(1, WordLadderSession.roundCount)} of ${WordLadderSession.roundCount}',
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
                      backgroundColor: const Color(0xFFE7ECE8),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: finished
                        ? _Results(
                            solved: session.solved,
                            mistakes: session.mistakes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : _playArea(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playArea() {
    final prompt = session.prompt;
    final pathSoFar = session.current.words.take(prompt.rung).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _softLilac,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Column(
            children: [
              const Text(
                'CHANGE ONE LETTER AT A TIME',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WordBadge(word: session.current.words.first, accent: _teal),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 18, color: _muted),
                  ),
                  _WordBadge(word: prompt.targetWord, accent: _coral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Rung ${prompt.rung} of ${prompt.rungCount}',
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final word in pathSoFar)
                _PathChip(word: word, current: word == prompt.currentWord),
              const _PathChip(word: '?', current: false, pending: true),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Find a word one letter from “${prompt.currentWord.toUpperCase()}”',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: Center(
            child: Text(
              _feedback ?? 'Build a bridge from start to target.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _lastCorrect == false ? _coral : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_awaitingContinue)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const ValueKey('word-ladder-continue'),
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _lastCorrect == true && prompt.rung == 1
                    ? 'NEXT LADDER'
                    : _lastCorrect == true && prompt.rung == prompt.rungCount
                        ? 'NEXT LADDER'
                        : _lastCorrect == false
                            ? 'NEXT LADDER'
                            : 'NEXT RUNG',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          )
        else
          _ChoiceGrid(
            choices: prompt.choices,
            onChoose: _answer,
          ),
        const SizedBox(height: 5),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.choices, required this.onChoose});

  final List<String> choices;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final height = ((constraints.maxWidth - 8) / 2) / 2.8;
          return SizedBox(
            height: height * 2 + 8,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: choices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                final word = choices[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    key: ValueKey('word-ladder-choice-$word'),
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => onChoose(word),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _edge, width: 1.5),
                      ),
                      child: Text(
                        word.toUpperCase(),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _WordBadge extends StatelessWidget {
  const _WordBadge({required this.word, required this.accent});

  final String word;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: accent.withValues(alpha: 0.38)),
        ),
        child: Text(
          word.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      );
}

class _PathChip extends StatelessWidget {
  const _PathChip({
    required this.word,
    required this.current,
    this.pending = false,
  });

  final String word;
  final bool current;
  final bool pending;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: pending
              ? Colors.white
              : current
                  ? _softLilac
                  : _softMint,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: pending
                ? _edge
                : current
                    ? _purple
                    : _teal,
          ),
        ),
        child: Text(
          word.toUpperCase(),
          style: TextStyle(
            color: pending ? _muted : _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _Results extends StatelessWidget {
  const _Results({
    required this.solved,
    required this.mistakes,
    required this.passed,
    required this.onRetry,
  });

  final int solved;
  final int mistakes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.auto_awesome_rounded : Icons.refresh_rounded,
              size: 62,
              color: passed ? _teal : _coral,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'Word wizard!' : 'Keep building those bridges',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$solved ladders solved · $mistakes misses',
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
const _muted = Color(0xFF8B9690);
const _teal = Color(0xFF5D9E88);
const _coral = Color(0xFFC97D72);
const _purple = Color(0xFF8274AE);
const _softLilac = Color(0xFFF0ECF8);
const _softMint = Color(0xFFE5F2EA);
const _edge = Color(0xFFE6ECE7);
