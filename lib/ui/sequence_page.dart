import 'package:flutter/material.dart';
import '../game/sequence_generator.dart';
import '../game/game_objective.dart';
import 'floor_victory.dart';
import 'fantasy_ui.dart';

class SequencePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int questions) onSessionEnd;
  const SequencePage({super.key, this.floor, required this.onComplete,
    required this.onSessionEnd});
  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  int round = 0;
  int correct = 0;
  bool done = false;
  late SequencePuzzle puzzle;
  bool passed = false;
  bool resultPresented = false;
  bool answering = false;
  int? selectedAnswer;
  bool selectedCorrect = false;

  @override
  void initState() {
    super.initState();
    _buildChoices();
  }

  void _buildChoices() {
    puzzle = const SequenceGenerator().generate(
      floor: widget.floor ?? 2, round: round,
    );
  }

  Future<void> answer(int chosen) async {
    if (done || answering) return;
    final wasCorrect = chosen == puzzle.answer;
    setState(() {
      answering = true;
      selectedAnswer = chosen;
      selectedCorrect = wasCorrect;
    });
    // The player must see whether the answer was right before it disappears.
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    setState(() {
      if (wasCorrect) correct++;
      round++;
      answering = false;
      selectedAnswer = null;
      if (round >= 3) {
        done = true;
        passed = const ObjectiveCatalog()
            .forGame('numberSequence', floor: widget.floor)
            .isComplete(correct);
      } else {
        _buildChoices();
      }
    });
    if (done) widget.onSessionEnd(correct, 3);
    if (done && passed && widget.floor != null) _onVictory();
  }

  Future<void> _onVictory() async {
    if (resultPresented || !mounted || widget.floor == null) return;
    resultPresented = true;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: '$correct of 3 patterns solved!',
      detail: 'Another neuron is waiting in the network.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) {
    final objective = const ObjectiveCatalog().forGame(
      'numberSequence', floor: widget.floor);
    return Scaffold(
      backgroundColor: const Color(0xFFCDE6FA),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Number Trail', style: TextStyle(
          fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFE3EFFF),
        foregroundColor: const Color(0xFF2B427D),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(padding: const EdgeInsets.only(right: 18),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900, color: Color(0xFF697AA9))))),
        ],
      ),
      body: FantasyScene(child: SafeArea(child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD06C), size: 23),
                const SizedBox(width: 8),
                Expanded(child: Text(objective.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800,
                    color: Color(0xFF273D75), fontSize: 14))),
                Text(done ? '$correct / 3' : '${round + 1} / 3',
                  style: const TextStyle(fontWeight: FontWeight.w900,
                    color: Color(0xFF665AC1))),
              ]),
              const SizedBox(height: 12),
              Expanded(child: LayoutBuilder(builder: (context, space) {
                return Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!done) ...[
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: (space.maxHeight * .20).clamp(65.0, 120.0).toDouble()),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xF8FFFFFF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFA6BEEA), width: 2)),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: FittedBox(
                            key: ValueKey<int>(round),
                            fit: BoxFit.scaleDown,
                            child: Text('${puzzle.numbers.join("   ")}   ?',
                              style: const TextStyle(fontSize: 30,
                                color: Color(0xFF273F79),
                                fontWeight: FontWeight.w900)))),
                      ),
                      SizedBox(height: (space.maxHeight * .035).clamp(8.0, 19.0).toDouble()),
                      SizedBox(
                        height: (space.maxHeight * .34).clamp(126.0, 198.0).toDouble(),
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: (space.maxWidth - 12) /
                            ((space.maxHeight * .34).clamp(126.0, 198.0) - 12),
                          children: [
                            for (final v in puzzle.choices)
                              AnimatedScale(
                                scale: answering && selectedAnswer == v ? 1.05 : 1,
                                duration: const Duration(milliseconds: 160),
                                child: Material(
                                  color: answering && selectedAnswer == v
                                    ? (selectedCorrect
                                      ? const Color(0xFF6BDDBB)
                                      : const Color(0xFFFFA5B3))
                                    : const Color(0xFFDDD9FF),
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: answering ? null : () => answer(v),
                                    child: Center(child: Text('$v',
                                      style: const TextStyle(fontSize: 25,
                                        color: Color(0xFF2A3873),
                                        fontWeight: FontWeight.w900))),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.stars_rounded,
                        size: 60, color: Color(0xFFFFD26F)),
                      const SizedBox(height: 12),
                      Text('Correct: $correct / 3', style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w900,
                        color: Color(0xFF273D75))),
                      const SizedBox(height: 18),
                      if (widget.floor == null || !passed)
                        FilledButton.icon(
                          onPressed: () {
                            if (passed) {
                              Navigator.pop(context);
                            } else {
                              setState(() {
                                round = 0; correct = 0; done = false;
                                passed = false; resultPresented = false;
                                answering = false; selectedAnswer = null;
                                _buildChoices();
                              });
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(passed ? 'Back to map' : 'Try again')),
                    ],
                  ]);
              })),
            ]),
          ),
        ),
      ))),
    );
  }
}
