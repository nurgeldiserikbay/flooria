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
  int? _wrongChoice;
  String _feedback = 'PICK THE VALUE THAT CONTINUES THE PATTERN';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = NumberSequenceEngine.forLevel(level);
    _wrongPulse = 0;
    _wrongChoice = null;
    _feedback = 'PICK THE VALUE THAT CONTINUES THE PATTERN';
  }

  void _choose(int value) {
    final result = _engine.choose(value);
    if (result == SequenceAnswer.ignored) return;
    if (result == SequenceAnswer.wrong) {
      HapticFeedback.selectionClick();
      setState(() {
        _wrongPulse++;
        _wrongChoice = value;
        _feedback = 'NOT QUITE · CHECK HOW THE NUMBERS CHANGE';
      });
      return;
    }
    HapticFeedback.lightImpact();
    if (result == SequenceAnswer.completed) {
      setState(() {
        _wrongChoice = null;
        _feedback = 'ALL FIVE PATTERNS SOLVED · GREAT JOB!';
      });
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: {'math':
        ((_engine.correct / (_engine.correct + _engine.mistakes)) * 100).round()});
      return;
    }
    setState(() {
      _wrongChoice = null; // New round starts with clean feedback.
      _feedback = 'GREAT ANSWER · FIND THE NEXT PATTERN';
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
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
          Semantics(
            key: const ValueKey('sequence-board-state'),
            label: 'Round ${_engine.correct + 1} of 5. '
                'Number pattern: ${_engine.terms.join(', ')}, unknown next term. '
                '${_engine.mistakes} incorrect attempts.',
            child: Shake(trigger: _wrongPulse, child: Container(
            width: cardSide,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: _palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFEEDCC5),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x29554332),
                  blurRadius: 16, offset: Offset(0, 5)),
              ],
            ),
            child: Column(children: [
              Text('WHAT COMES NEXT?', style: TextStyle(color: _palette.muted,
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: reducedMotion ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                child: Wrap(
                  key: ValueKey('sequence-round-${_engine.round}'),
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8, runSpacing: 12,
                  children: [
                    for (final term in _engine.terms)
                      _TermTile(value: '$term'),
                    const _TermTile(value: '?', highlighted: true),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
                children: [for (final choice in _engine.choices)
                  SizedBox(width: (cardSide - 54) / 2, height: 56,
                    child: ChunkyButton(
                      key: ValueKey('sequence-choice-$choice'),
                      onPressed: reported ? null : () => _choose(choice),
                      color: _wrongChoice == choice
                          ? const Color(0xFFFFDCDD)
                          : const Color(0xFFFFE5BC),
                      edgeColor: _wrongChoice == choice
                          ? const Color(0xFFD46D73)
                          : const Color(0xFFCBA773),
                      semanticLabel: 'Answer $choice',
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_wrongChoice == choice) ...[
                            const Icon(Icons.close_rounded,
                              color: Color(0xFFA94C59), size: 19),
                            const SizedBox(width: 3),
                          ],
                          Text('$choice', style: TextStyle(
                            color: _wrongChoice == choice
                                ? const Color(0xFFA94C59) : _palette.ink,
                            fontSize: 21, fontWeight: FontWeight.w900,
                          )),
                        ],
                      ),
                    ))]),
            ]),
          ))),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.mistakes == 0 ? 3 : _engine.mistakes < 3 ? 2 : 1,
                detail: 'Solved five number patterns.', onReplay: replayLevel,
                onNext: nextLevel))
          else
            HintLine(_feedback, palette: _palette),
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
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: highlighted
            ? const [Color(0xFFFFF0D5), Color(0xFFFFD893)]
            : const [Colors.white, Color(0xFFFFF4E7)],
      ),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: highlighted ? _palette.accent
            : const Color(0xFFEADACA),
        width: highlighted ? 2 : 1,
      ),
      boxShadow: highlighted ? const [
        BoxShadow(color: Color(0x36E79D43),
          blurRadius: 9, offset: Offset(0, 3)),
      ] : null,
    ),
    alignment: Alignment.center,
    child: Text(value, style: TextStyle(
      color: highlighted ? _palette.accent : _palette.ink,
      fontSize: 18, fontWeight: FontWeight.w900,
    )),
  );
}
