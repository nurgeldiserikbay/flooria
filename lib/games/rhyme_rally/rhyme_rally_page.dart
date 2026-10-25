import 'package:flutter/material.dart';

import 'rhyme_rally_engine.dart';

class RhymeRallyPage extends StatefulWidget {
  const RhymeRallyPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<RhymeRallyPage> createState() => _RhymeRallyPageState();
}

class _RhymeRallyPageState extends State<RhymeRallyPage> {
  static const _paper = Color(0xFFFFF7EB);
  static const _ink = Color(0xFF3D4969);
  static const _muted = Color(0xFF7E88A3);
  static const _coral = Color(0xFFF18A78);

  late RhymeRallySession session;
  int _revision = 0;
  bool _reported = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _feedback = null;
    _feedbackIsError = false;
    session = RhymeRallySession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 13579 + _revision++,
      level: widget.floor ?? 1,
    );
  }

  void _answer(int optionIndex) {
    if (_reported) return;
    final wasCorrect = optionIndex == session.current.correctIndex;
    final result = session.answer(optionIndex);
    if (result == RhymeAnswerResult.invalid) return;
    setState(() {
      _feedbackIsError = !wasCorrect;
      _feedback = switch (result) {
        RhymeAnswerResult.invalid => null,
        RhymeAnswerResult.incorrect => 'Not that one — listen for the ending sound.',
        RhymeAnswerResult.correct => 'That rhymes! Next word…',
        RhymeAnswerResult.sessionComplete => wasCorrect
            ? 'Rhyme round complete!'
            : 'Round complete — review the ending sounds.',
      };
    });
    if (session.finished) _finish();
  }

  void _finish() {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.correct, session.mistakes);
    if (session.passed && widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    final current = session.current;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Rhyme Rally',
            style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: _ink,
        backgroundColor: _paper,
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _muted)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: _coral, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Find a word with the same ending sound.',
                            style: TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                      Text(
                        complete
                            ? '${session.correct} / ${RhymeRallySession.roundCount}'
                            : '${session.round + 1} / ${RhymeRallySession.roundCount}',
                        style: const TextStyle(
                            color: _coral, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF5E2CB),
                      color: _coral,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Expanded(
                    child: complete
                        ? _ResultsPanel(
                            session: session,
                            onRetry: !session.passed || widget.floor == null
                                ? () => setState(_startSession)
                                : null,
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _TargetCard(word: current.target.text),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('WHICH WORD RHYMES WITH…?',
                                  style: TextStyle(
                                      color: _muted,
                                      letterSpacing: 1.2,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  for (var index = 0;
                                      index < current.options.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: _WordOption(
                                        key: ValueKey('rhyme-option-$index'),
                                        word: current.options[index].text,
                                        onPressed: () => _answer(index),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 9),
                              SizedBox(
                                height: 22,
                                child: Text(
                                  _feedback ?? 'Say both words aloud to compare.',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: _feedbackIsError ? _coral : _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Correct: ${session.correct}   •   Misses: ${session.mistakes}',
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
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

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 330, maxHeight: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFEACD), Color(0xFFFFD9C7)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF5CDAA), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AF18A78),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded,
                color: Color(0xFFE57B6C), size: 34),
            const SizedBox(height: 9),
            Text(
              word.toUpperCase(),
              semanticsLabel: 'Target word: $word',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF38496D),
                  fontSize: 38,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('TARGET WORD',
                style: TextStyle(
                    color: Color(0xFF8A7691),
                    letterSpacing: 1.4,
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _WordOption extends StatelessWidget {
  const _WordOption({
    super.key,
    required this.word,
    required this.onPressed,
  });

  final String word;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Word $word',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBD9C4), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D3D4969),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(word.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF3D4969),
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
      );
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final RhymeRallySession session;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFEBD9C4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                session.passed ? Icons.celebration_rounded : Icons.replay_rounded,
                color: session.passed
                    ? const Color(0xFFEAB14E)
                    : const Color(0xFFF18A78),
                size: 46,
              ),
              const SizedBox(height: 10),
              Text(
                session.passed ? 'Rhyme star!' : 'Keep listening',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF3D4969),
                    fontSize: 21,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'You found ${session.correct} of ${RhymeRallySession.roundCount} rhymes.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF7E88A3), fontWeight: FontWeight.w600),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('PLAY AGAIN'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF18A78),
                      foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      );
}
