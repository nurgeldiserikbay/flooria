import 'package:flutter/material.dart';

import 'ink_switch_engine.dart';

/// Read the ink color of a word while ignoring the color it spells.
class InkSwitchPage extends StatefulWidget {
  const InkSwitchPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<InkSwitchPage> createState() => _InkSwitchPageState();
}

class _InkSwitchPageState extends State<InkSwitchPage> {
  static const _hues = <InkHue, _HueStyle>{
    InkHue.coral: _HueStyle('CORAL', Color(0xFFE97863)),
    InkHue.blue: _HueStyle('BLUE', Color(0xFF4F8FC4)),
    InkHue.violet: _HueStyle('VIOLET', Color(0xFF9171C5)),
    InkHue.mint: _HueStyle('MINT', Color(0xFF469E7A)),
    InkHue.amber: _HueStyle('AMBER', Color(0xFFC58B28)),
    InkHue.teal: _HueStyle('TEAL', Color(0xFF348F91)),
  };
  static const _ink = Color(0xFF4B6967);
  static const _paleMint = Color(0xFFCDEBDD);

  late InkSwitchSession session;
  int revision = 0;
  bool reported = false;
  bool? lastWasCorrect;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    revision++;
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 104729
        : widget.floor! * 104729 + revision;
    session = InkSwitchSession(seed: seed);
    reported = false;
    lastWasCorrect = null;
  }

  void _answer(int optionIndex, int visibleRound) {
    if (visibleRound != session.round || session.finished) return;
    final isCorrect = session.current.correctIndex == optionIndex;
    if (!session.answer(optionIndex)) return;
    setState(() {
      lastWasCorrect = isCorrect;
    });
    if (!session.finished || reported) return;
    reported = true;
    widget.onSessionEnd(session.correct, session.mistakes);
    if (widget.floor != null && session.passed) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    final round = session.current;
    final visibleRound = session.round;
    final progress = finished ? InkSwitchSession.roundCount : session.round + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4F1),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Ink Switch', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF6FBF9),
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
            colors: [Color(0xFFD8EFE6), Color(0xFFF3F8FF), Color(0xFFFFF0DE)],
          )),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.palette_outlined, color: Color(0xFF5C9B88), size: 23),
              const SizedBox(width: 8),
              Expanded(child: Text(
                finished
                    ? (session.passed ? 'Color control complete!' : 'Ready for another try?')
                    : 'Read the ink. Ignore the word.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 15),
              )),
              Text('$progress / ${InkSwitchSession.roundCount}', style: const TextStyle(
                color: Color(0xFF688C88), fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.round / InkSwitchSession.roundCount,
              minHeight: 7,
              backgroundColor: const Color(0xFFD5E7E0),
              color: const Color(0xFF72B79B),
            )),
            const SizedBox(height: 8),
            Expanded(child: finished
                ? _ResultsPanel(correct: session.correct, mistakes: session.mistakes, passed: session.passed)
                : Column(children: [
                    const SizedBox(height: 8),
                    const Text('TAP THE COLOR OF THE LETTERS', textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF78928B), fontSize: 11,
                        letterSpacing: .8, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Expanded(child: Center(child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 250, minHeight: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x18738A80), blurRadius: 18, offset: Offset(0, 7))],
                        ),
                        child: Text(
                          _hues[round.wordHue]!.label,
                          key: ValueKey<String>('ink-word-${session.round}'),
                          style: TextStyle(
                            color: _hues[round.inkHue]!.color,
                            fontSize: 48,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ))),
                    const SizedBox(height: 8),
                    LayoutBuilder(builder: (context, bounds) {
                      final gap = 10.0;
                      final width = (bounds.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var index = 0; index < round.options.length; index++)
                            SizedBox(
                              width: width,
                              height: 54,
                              child: _AnswerButton(
                                key: ValueKey<String>('ink-option-$visibleRound-$index'),
                                label: _hues[round.options[index]]!.label,
                                color: _hues[round.options[index]]!.color,
                                onPressed: () => _answer(index, visibleRound),
                              ),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 10),
                    Text(
                      lastWasCorrect == null ? '${session.correct} right so far'
                          : lastWasCorrect! ? 'Nice! Next color' : 'Good try. New color',
                      style: const TextStyle(color: Color(0xFF708A84), fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                  ])),
            if (finished && (widget.floor == null || !session.passed)) ...[
              const SizedBox(height: 8),
              _ActionButton(label: 'PLAY AGAIN', onPressed: () => setState(_startSession)),
            ] else if (finished) ...[
              const SizedBox(height: 8),
              Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(16)),
                child: const Text('TOWER LEVEL COMPLETE', style: TextStyle(color: _ink, fontWeight: FontWeight.w900, letterSpacing: .7)),
              ),
            ],
          ]),
        ),
      ))),
    );
  }
}

class _HueStyle {
  const _HueStyle(this.label, this.color);
  final String label;
  final Color color;
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({super.key, required this.label, required this.color, required this.onPressed});
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .8),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .55), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .5),
        ),
        child: Text(label),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .74), borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(passed ? Icons.auto_awesome_rounded : Icons.spa_rounded,
            size: 46, color: passed ? const Color(0xFF5AA785) : const Color(0xFFE29A72)),
          const SizedBox(height: 8),
          Text('$correct / ${InkSwitchSession.roundCount}', style: const TextStyle(
            color: _InkSwitchPageState._ink, fontSize: 29, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 5),
          Text('$mistakes ${mistakes == 1 ? 'mistake' : 'mistakes'}',
            style: const TextStyle(color: Color(0xFF728B84), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(passed ? 'You stayed focused through the color conflict.' : 'Try again and let the ink guide you.',
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
            backgroundColor: _paleMint,
            foregroundColor: _ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7),
          ),
          child: Text(label),
        ),
      );
}
