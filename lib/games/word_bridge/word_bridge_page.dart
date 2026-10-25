import 'package:flutter/material.dart';

import 'word_bridge_engine.dart';

const _ink = Color(0xFF4F6967);
const _mint = Color(0xFFC8E8D8);
const _coral = Color(0xFFF4A98E);

/// Solve short word analogies by carrying a relationship across the bridge.
class WordBridgePage extends StatefulWidget {
  const WordBridgePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<WordBridgePage> createState() => _WordBridgePageState();
}

class _WordBridgePageState extends State<WordBridgePage> {
  late WordBridgeSession session;
  int revision = 0;
  bool reported = false;
  bool? lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    revision++;
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 3253
        : widget.floor! * 3253 + revision;
    session = WordBridgeSession(seed: seed);
    reported = false;
    lastAnswerCorrect = null;
  }

  void _answer(int optionIndex, int visibleRound) {
    if (visibleRound != session.round || session.finished) return;
    final correct = optionIndex == session.current.correctIndex;
    if (!session.answer(optionIndex)) return;
    setState(() => lastAnswerCorrect = correct);
    if (!session.finished || reported) return;
    reported = true;
    widget.onSessionEnd(session.correct, session.mistakes);
    if (widget.floor != null && session.passed) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    final question = session.current;
    final visibleRound = session.round;
    final progress = finished ? WordBridgeSession.roundCount : visibleRound + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4F0),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Word Bridge', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FBF9),
        foregroundColor: _ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                color: Color(0xFF789B95), fontSize: 12, fontWeight: FontWeight.w900,
              )),
            )),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD7EEE4), Color(0xFFF3F8FF), Color(0xFFFFF0DF)],
          )),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.link_rounded, color: Color(0xFF6C9F8A), size: 23),
              const SizedBox(width: 8),
              Expanded(child: Text(
                finished ? (session.passed ? 'Bridge builder!' : 'Try another set')
                    : 'Carry the same connection across',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 15),
              )),
              Text('$progress / ${WordBridgeSession.roundCount}', style: const TextStyle(
                color: Color(0xFF688C88), fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.round / WordBridgeSession.roundCount,
              minHeight: 7,
              backgroundColor: const Color(0xFFD5E7E0),
              color: const Color(0xFF78B398),
            )),
            const SizedBox(height: 8),
            Expanded(child: finished
                ? _ResultsPanel(correct: session.correct, mistakes: session.mistakes, passed: session.passed)
                : _QuestionPanel(
                    question: question,
                    visibleRound: visibleRound,
                    lastAnswerCorrect: lastAnswerCorrect,
                    onAnswer: _answer,
                  )),
            if (finished && (widget.floor == null || !session.passed)) ...[
              const SizedBox(height: 8),
              _ActionButton(label: 'PLAY AGAIN', onPressed: () => setState(_startSession)),
            ] else if (finished) ...[
              const SizedBox(height: 8),
              Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(16)),
                child: const Text('TOWER LEVEL COMPLETE', style: TextStyle(color: _ink, fontWeight: FontWeight.w900, letterSpacing: .7)),
              ),
            ],
          ]),
        ),
      ))),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.question,
    required this.visibleRound,
    required this.lastAnswerCorrect,
    required this.onAnswer,
  });

  final WordBridgeQuestion question;
  final int visibleRound;
  final bool? lastAnswerCorrect;
  final void Function(int optionIndex, int visibleRound) onAnswer;

  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 4),
        const Text('FIND THE WORD THAT COMPLETES THE SAME RELATIONSHIP', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF78928B), fontSize: 10, letterSpacing: .5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _PairCard(first: question.firstWord, second: question.relatedWord, index: 1),
        const SizedBox(height: 8),
        _PairCard(first: question.bridgeWord, second: '?', index: 2, highlighted: true),
        const SizedBox(height: 10),
        const Align(alignment: Alignment.centerLeft, child: Text('CHOOSE A BRIDGE WORD', style: TextStyle(
          color: Color(0xFF78928B), fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w900,
        ))),
        const SizedBox(height: 7),
        for (var index = 0; index < question.options.length; index++) ...[
          if (index > 0) const SizedBox(height: 7),
          SizedBox(
            height: 51,
            width: double.infinity,
            child: _WordOption(
              key: ValueKey<String>('word-bridge-option-$visibleRound-$index'),
              label: question.options[index],
              onPressed: () => onAnswer(index, visibleRound),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(lastAnswerCorrect == null ? '${_tierLabel(question.difficulty)} relationship'
            : lastAnswerCorrect! ? 'Well connected! Keep going.' : 'Good try. Find the shared link.',
          style: const TextStyle(color: Color(0xFF708A84), fontSize: 12, fontWeight: FontWeight.w800)),
      ]);
}

String _tierLabel(int difficulty) => switch (difficulty) {
      1 => 'Warm-up',
      2 => 'Steady',
      _ => 'Challenge',
    };

class _PairCard extends StatelessWidget {
  const _PairCard({required this.first, required this.second, required this.index, this.highlighted = false});

  final String first;
  final String second;
  final int index;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: highlighted ? .86 : .7),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: highlighted ? const Color(0xFFB9DEC9) : Colors.white, width: 2),
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: highlighted ? _coral.withValues(alpha: .28) : _mint,
              shape: BoxShape.circle),
            child: Text('$index', style: const TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 11),
          Expanded(child: _WordText(first)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':', style: TextStyle(color: Color(0xFF8CA39B), fontSize: 20, fontWeight: FontWeight.w900))),
          Expanded(child: _WordText(second, emphasized: highlighted)),
        ]),
      );
}

class _WordText extends StatelessWidget {
  const _WordText(this.word, {this.emphasized = false});
  final String word;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(word.toUpperCase(), maxLines: 1,
          style: TextStyle(color: emphasized ? _coral : _ink, fontSize: 21,
            letterSpacing: .8, fontWeight: FontWeight.w900)),
      );
}

class _WordOption extends StatelessWidget {
  const _WordOption({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .8),
          foregroundColor: _ink,
          side: const BorderSide(color: Color(0xFFD6E9E0), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: .5),
        ),
        child: Text(label.toUpperCase()),
      );
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.correct, required this.mistakes, required this.passed});

  final int correct;
  final int mistakes;
  final bool passed;

  @override
  Widget build(BuildContext context) => Center(child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(26)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(passed ? Icons.auto_awesome_rounded : Icons.menu_book_rounded,
            size: 44, color: passed ? const Color(0xFF5AA785) : const Color(0xFFE29A72)),
          const SizedBox(height: 7),
          Text('$correct / ${WordBridgeSession.roundCount}', style: const TextStyle(color: _ink, fontSize: 29, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$mistakes ${mistakes == 1 ? 'mistake' : 'mistakes'}',
            style: const TextStyle(color: Color(0xFF728B84), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(passed ? 'You carried each connection across.' : 'Look for how the first two words relate.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF607C74), fontWeight: FontWeight.w700)),
        ]),
      ));
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _mint,
            foregroundColor: _ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7),
          ),
          child: Text(label),
        ),
      );
}
