import 'package:flutter/material.dart';

import 'chance_garden_engine.dart';

const _coral = Color(0xFFE77C69);
const _blue = Color(0xFF659BC5);
const _ink = Color(0xFF4D6C68);
const _mint = Color(0xFFCBE9D9);

/// Inspect a sample and choose the jar most likely to have produced it.
class ChanceGardenPage extends StatefulWidget {
  const ChanceGardenPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int mistakes) onSessionEnd;

  @override
  State<ChanceGardenPage> createState() => _ChanceGardenPageState();
}

class _ChanceGardenPageState extends State<ChanceGardenPage> {
  late ChanceGardenSession session;
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
        ? DateTime.now().microsecondsSinceEpoch + revision * 7919
        : widget.floor! * 7919 + revision;
    session = ChanceGardenSession(seed: seed);
    reported = false;
    lastAnswerCorrect = null;
  }

  void _answer(int jarIndex, int visibleRound) {
    if (visibleRound != session.round || session.finished) return;
    final correct = jarIndex == session.current.correctJarIndex;
    if (!session.answer(jarIndex)) return;
    setState(() => lastAnswerCorrect = correct);
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
    final progress = finished ? ChanceGardenSession.roundCount : visibleRound + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5EF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Chance Garden', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FBF7),
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
            colors: [Color(0xFFD8EFE0), Color(0xFFF3F8FF), Color(0xFFFFF0DD)],
          )),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.science_outlined, color: Color(0xFF699D7D), size: 23),
              const SizedBox(width: 8),
              Expanded(child: Text(
                finished ? (session.passed ? 'A sharp prediction!' : 'Try another sample')
                    : 'Which jar is more likely?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 15),
              )),
              Text('$progress / ${ChanceGardenSession.roundCount}', style: const TextStyle(
                color: Color(0xFF688C88), fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: session.round / ChanceGardenSession.roundCount,
              minHeight: 7,
              backgroundColor: const Color(0xFFD5E7DD),
              color: const Color(0xFF7BB58F),
            )),
            const SizedBox(height: 8),
            Expanded(child: finished
                ? _ResultsPanel(correct: session.correct, mistakes: session.mistakes, passed: session.passed)
                : _RoundView(
                    round: round,
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

class _RoundView extends StatelessWidget {
  const _RoundView({
    required this.round,
    required this.visibleRound,
    required this.lastAnswerCorrect,
    required this.onAnswer,
  });

  final ChanceGardenRound round;
  final int visibleRound;
  final bool? lastAnswerCorrect;
  final void Function(int jarIndex, int visibleRound) onAnswer;

  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 4),
        const Text('COMPARE THE SAMPLE WITH EACH TEN-BEAD JAR', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF78928B), fontSize: 11, letterSpacing: .6, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Expanded(child: Center(child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .77),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('SAMPLE BEADS', style: TextStyle(color: Color(0xFF8A9C96), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 7,
              children: [for (var index = 0; index < round.sample.length; index++)
                _Bead(color: _beadColor(round.sample[index]), size: 24, key: ValueKey<String>('sample-bead-$visibleRound-$index'))],
            ),
            const SizedBox(height: 7),
            Text('${round.coralSampleCount} coral • ${round.blueSampleCount} blue',
              style: const TextStyle(color: Color(0xFF708780), fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ))),
        const SizedBox(height: 9),
        Expanded(flex: 2, child: Row(children: [
          for (var index = 0; index < round.jars.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            Expanded(child: _JarChoice(
              key: ValueKey<String>('chance-choice-card-$visibleRound-$index'),
              index: index,
              visibleRound: visibleRound,
              jar: round.jars[index],
              onTap: () => onAnswer(index, visibleRound),
            )),
          ],
        ])),
        const SizedBox(height: 8),
        Text(lastAnswerCorrect == null ? '${visibleRound < 3 ? 'Wide' : visibleRound < 7 ? 'Closer' : 'Very close'} mixes • ${visibleRound < 3 ? 'easy' : visibleRound < 7 ? 'steady' : 'tricky'}'
            : lastAnswerCorrect! ? 'Good read! Look at the next sample.' : 'Keep comparing the color ratios.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF708A84), fontSize: 12, fontWeight: FontWeight.w800)),
      ]);
}

class _JarChoice extends StatelessWidget {
  const _JarChoice({super.key, required this.index, required this.visibleRound, required this.jar, required this.onTap});

  final int index;
  final int visibleRound;
  final JarMix jar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Choose jar ${index == 0 ? 'A' : 'B'}, ${jar.coralCount} coral and ${jar.blueCount} blue beads',
        child: Material(
          key: ValueKey<String>('chance-answer-$visibleRound-$index'),
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('JAR ${index == 0 ? 'A' : 'B'}', style: const TextStyle(color: _ink, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 92,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var bead = 0; bead < JarMix.capacity; bead++)
                        _Bead(color: bead < jar.coralCount ? _coral : _blue, size: 15),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text('${jar.coralCount} coral · ${jar.blueCount} blue',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF708780), fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(13)),
                  child: const Text('CHOOSE', textAlign: TextAlign.center,
                    style: TextStyle(color: _ink, fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _Bead extends StatelessWidget {
  const _Bead({super.key, required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x1670887D), blurRadius: 3, offset: Offset(0, 1))],
        ),
      );
}

Color _beadColor(BeadColor bead) => bead == BeadColor.coral ? _coral : _blue;

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.correct, required this.mistakes, required this.passed});

  final int correct;
  final int mistakes;
  final bool passed;

  @override
  Widget build(BuildContext context) => Center(child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .76), borderRadius: BorderRadius.circular(26)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(passed ? Icons.auto_awesome_rounded : Icons.eco_rounded,
            size: 44, color: passed ? const Color(0xFF5AA785) : const Color(0xFFE29A72)),
          const SizedBox(height: 7),
          Text('$correct / ${ChanceGardenSession.roundCount}', style: const TextStyle(color: _ink, fontSize: 29, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$mistakes ${mistakes == 1 ? 'mistake' : 'mistakes'}',
            style: const TextStyle(color: Color(0xFF728B84), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(passed ? 'You spotted which mix best fits the evidence.' : 'Compare the sample counts with each jar again.',
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
