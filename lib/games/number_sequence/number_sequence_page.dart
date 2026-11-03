import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'number_sequence_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF4E3), surface: Colors.white, ink: Color(0xFF554332),
  muted: Color(0xFF94816B), accent: Color(0xFFE79D43), edge: Color(0xFF554332),
);

Widget buildNumberSequencePage(BuildContext context, GameLaunch launch) =>
    NumberSequencePage(launch: launch);

class NumberSequencePage extends StatefulWidget {
  const NumberSequencePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<NumberSequencePage> createState() => _NumberSequencePageState();
}

class _NumberSequencePageState extends State<NumberSequencePage>
    with LevelFlow<NumberSequencePage> {
  late NumberSequenceEngine _engine;
  int _wrongPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = NumberSequenceEngine.forLevel(level);

  void _choose(int value) {
    final result = _engine.choose(value);
    if (result == SequenceAnswer.ignored) return;
    if (result == SequenceAnswer.wrong) {
      HapticFeedback.selectionClick();
      setState(() => _wrongPulse++);
      return;
    }
    HapticFeedback.lightImpact();
    if (result == SequenceAnswer.completed) {
      setState(() {});
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: {'math':
        ((_engine.correct / (_engine.correct + _engine.mistakes)) * 100).round()});
      return;
    }
    setState(() {
      // The engine has advanced itself to the next generated sequence.
    });
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Number Sequence',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final cardSide = min(constraints.maxWidth - 36, 390.0).toDouble();
      return Center(child: SingleChildScrollView(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'ROUND', value: '${_engine.correct}/5', palette: _palette),
                StatChip(label: 'SCORE', value: '${_engine.score}', palette: _palette),
              ])),
          const SizedBox(height: 18),
          SegmentBar(total: 5, done: _engine.correct, palette: _palette),
          const SizedBox(height: 22),
          Shake(trigger: _wrongPulse, child: Container(
            width: cardSide,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(color: _palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: Column(children: [
              const Text('WHAT COMES NEXT?', style: TextStyle(color: _palette.muted,
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 22),
              Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8, runSpacing: 12, children: [
                  for (final term in _engine.terms) _TermTile(value: '$term'),
                  const _TermTile(value: '?', highlighted: true),
                ]),
              const SizedBox(height: 26),
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
                children: [for (final choice in _engine.choices)
                  SizedBox(width: (cardSide - 54) / 2, height: 56,
                    child: ChunkyButton(onPressed: reported ? null : () => _choose(choice),
                      color: const Color(0xFFFFE5BC), edgeColor: _palette.edge,
                      padding: EdgeInsets.zero, child: Text('$choice',
                        style: const TextStyle(color: _palette.ink,
                          fontSize: 21, fontWeight: FontWeight.w900))))]),
            ]),
          )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.mistakes == 0 ? 3 : _engine.mistakes < 3 ? 2 : 1,
                detail: 'Solved five number patterns.', onReplay: replayLevel,
                onNext: nextLevel))
          else
            const HintLine('PICK THE VALUE THAT CONTINUES THE PATTERN',
              palette: _palette),
        ],
      )));
    }),
  );
}

class _TermTile extends StatelessWidget {
  const _TermTile({required this.value, this.highlighted = false});
  final String value;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    width: 54, height: 58,
    decoration: BoxDecoration(color: highlighted ? const Color(0xFFFFE5BC)
        : const Color(0xFFFFF8EF), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: highlighted ? _palette.accent : const Color(0xFFE5D8C8),
        width: highlighted ? 2 : 1.5)),
    alignment: Alignment.center,
    child: Text(value, style: TextStyle(color: highlighted ? _palette.accent : _palette.ink,
      fontSize: 18, fontWeight: FontWeight.w900)),
  );
}
