import 'package:flutter/material.dart';

import 'causal_lab_engine.dart';

class CausalLabPage extends StatefulWidget {
  const CausalLabPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int total) onSessionEnd;

  @override
  State<CausalLabPage> createState() => _CausalLabPageState();
}

class _CausalLabPageState extends State<CausalLabPage> {
  late CausalLabSession game;
  int revision = 0;
  bool reported = false;
  bool? lastCorrect;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = CausalLabSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + revision
          : widget.floor! * 7919 + revision,
      level: widget.floor ?? 1,
    );
    reported = false;
    lastCorrect = null;
  }

  void _test(Experiment experiment) {
    if (reported || !game.answer(experiment)) return;
    final informative = game.rounds[game.round - 1].isInformative(experiment);
    setState(() => lastCorrect = informative);
    if (!game.finished) return;
    reported = true;
    widget.onSessionEnd(game.correct, game.roundCount);
    if (widget.floor != null && game.passed) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = game.finished;
    final round = game.current;
    const ink = Color(0xFF405676);
    const muted = Color(0xFF7587A0);
    const paper = Color(0xFFF2F8EE);
    const green = Color(0xFF66A886);
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Causal Lab', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF8FCF5),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: muted)),
            )),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: complete
              ? _Results(correct: game.correct, total: game.roundCount,
                  passed: game.passed, onRetry: () => setState(() { revision++; _restart(); }))
              : Column(children: [
                  Row(children: [
                    const Icon(Icons.biotech_rounded, color: green, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Pick a test that separates the models.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink))),
                    Text('${game.round + 1} / ${game.roundCount}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: green)),
                  ]),
                  const SizedBox(height: 9),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
                    value: game.round / game.roundCount, minHeight: 7,
                    backgroundColor: const Color(0xFFDCEBDD), color: green,
                  )),
                  const SizedBox(height: 12),
                  _ObservationCard(round: round),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: Text(
                    'TWO POSSIBLE EXPLANATIONS',
                    style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.1,
                      fontWeight: FontWeight.w900))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: _ModelCard(title: 'MODEL A', rule: round.firstModel)),
                    const SizedBox(width: 8),
                    Expanded(child: _ModelCard(title: 'MODEL B', rule: round.secondModel)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Which experiment would make their predictions differ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, color: ink, fontSize: 14)),
                  const SizedBox(height: 8),
                  Expanded(child: LayoutBuilder(builder: (context, constraints) {
                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: constraints.maxWidth / 2 / ((constraints.maxHeight - 8) / 2),
                      children: [for (final experiment in round.experiments)
                        _ExperimentButton(experiment: experiment,
                          onTap: () => _test(experiment))],
                    );
                  })),
                  const SizedBox(height: 8),
                  SizedBox(height: 20, child: Center(child: Text(
                    lastCorrect == null ? 'Change one or both conditions and compare.'
                        : lastCorrect! ? 'Good test — the models disagree.'
                        : 'Both models predict the same result for that test.',
                    style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700),
                  ))),
                ]),
        ),
      ))),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.round});
  final CausalRound round;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD4E6D6))),
    child: Row(children: [
      const Icon(Icons.visibility_rounded, color: Color(0xFF74A989), size: 22),
      const SizedBox(width: 9),
      Expanded(child: Text(
        'Observed: ${_conditions(round.observation)} → ${round.observedGrowth ? 'plant grew' : 'no growth'}',
        style: const TextStyle(color: Color(0xFF405676), fontWeight: FontWeight.w800, fontSize: 12))),
    ]),
  );
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.title, required this.rule});
  final String title;
  final CauseRule rule;

  @override
  Widget build(BuildContext context) => Container(
    height: 65,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0DFC0))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(title, style: const TextStyle(color: Color(0xFFA1885F),
        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const SizedBox(height: 3),
      FittedBox(child: Text(rule.label, style: const TextStyle(color: Color(0xFF66583E),
        fontWeight: FontWeight.w900, fontSize: 12))),
    ]),
  );
}

class _ExperimentButton extends StatelessWidget {
  const _ExperimentButton({required this.experiment, required this.onTap});
  final Experiment experiment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE5F2E7),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        key: ValueKey('causal-test-${experiment.sun ? 1 : 0}-${experiment.water ? 1 : 0}'),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC7E0CB))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _condition('☀', 'SUN', experiment.sun),
            const SizedBox(width: 9),
            _condition('💧', 'WATER', experiment.water),
          ]),
          const SizedBox(height: 6),
          const Text('RUN TEST', style: TextStyle(color: Color(0xFF59866C),
            fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900)),
        ]),
      ),
    ),
  );
}

Widget _condition(String icon, String name, bool enabled) => Column(children: [
  Text(icon, style: TextStyle(fontSize: 20, color: enabled ? null : const Color(0xFFB5BEB5))),
  Text('${enabled ? 'ON' : 'OFF'} $name', style: const TextStyle(
    color: Color(0xFF516C5B), fontSize: 8, fontWeight: FontWeight.w900)),
]);

String _conditions(Experiment experiment) =>
    'Sun ${experiment.sun ? 'ON' : 'OFF'}, water ${experiment.water ? 'ON' : 'OFF'}';

class _Results extends StatelessWidget {
  const _Results({required this.correct, required this.total, required this.passed,
    required this.onRetry});
  final int correct;
  final int total;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(passed ? Icons.eco_rounded : Icons.science_rounded,
        color: const Color(0xFF66A886), size: 58),
      const SizedBox(height: 12),
      Text(passed ? 'Sharp experiments!' : 'Lab complete',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22,
          color: Color(0xFF405676))),
      const SizedBox(height: 7),
      Text('$correct of $total tests separated the models.',
        style: const TextStyle(color: Color(0xFF7587A0), fontWeight: FontWeight.w700)),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
        label: const Text('TRY AGAIN')),
    ],
  ));
}
