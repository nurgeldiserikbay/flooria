import 'package:flutter/material.dart';

import 'pattern_trio_engine.dart';

/// Visual attribute reasoning, scoped entirely to its own module.
class PatternTrioPage extends StatefulWidget {
  const PatternTrioPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int attempts, int mistakes) onSessionEnd;

  @override
  State<PatternTrioPage> createState() => _PatternTrioPageState();
}

class _PatternTrioPageState extends State<PatternTrioPage> {
  static const ink = Color(0xFF354F79);
  static const accents = [
    Color(0xFFEE9F9E),
    Color(0xFF79CDB8),
    Color(0xFF9C96E3),
  ];

  late PatternTrioSession game;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    final floor = widget.floor;
    game = PatternTrioSession(
      seed: floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : floor * 1597 + revision,
    );
    reported = false;
  }

  void _select(int index) {
    if (reported || !game.tap(index)) return;
    setState(() {});
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.attempts, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _symbol(PatternCard card, double size) {
    final color = accents[card.color];
    return switch (card.shape) {
      0 => Icon(Icons.circle, size: size, color: color),
      1 => Icon(Icons.change_history_rounded, size: size, color: color),
      _ => Icon(Icons.square_rounded, size: size, color: color),
    };
  }

  Widget _card(int index) {
    final card = game.cards[index];
    final selected = game.selected.contains(index);
    return Material(
      color: selected ? const Color(0xFFD9D7FC)
          : const Color(0xFFF8FBFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('pattern-card-$index'),
        onTap: game.complete ? null : () => _select(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: selected ? 3 : 1.5,
              color: selected ? const Color(0xFF7974BE)
                  : const Color(0xFFBCCDE8),
            ),
          ),
          child: LayoutBuilder(builder: (context, bounds) {
            final iconSize = (bounds.maxWidth / (card.count + 2))
                .clamp(17.0, 30.0).toDouble();
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var n = 0; n <= card.count; n++)
                    _symbol(card, iconSize),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        toolbarHeight: 48,
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF5FAFF),
        title: const Text('Pattern Trio',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7587A8)))),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFCCEAF9), Color(0xFFE6E3FC),
                  Color(0xFFFFEBDD)],
              )),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.style_rounded,
                      color: Color(0xFF7C80C3)),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text('Find three matching rules',
                      style: TextStyle(color: ink,
                          fontSize: 13, fontWeight: FontWeight.w900)),
                  ),
                  Text('${game.round} / ${game.roundCount}',
                    style: const TextStyle(color: Color(0xFF7781AB),
                        fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 9),
                const Text(
                  'For EACH trait: all the same or all different.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ink,
                      fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text('Compare shape, color and number of symbols.',
                  style: TextStyle(fontSize: 12,
                    color: Color(0xFF647BA4)),
                  textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Expanded(child: LayoutBuilder(builder: (context, bounds) {
                  final side = bounds.biggest.shortestSide.clamp(0.0, 430.0);
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(2),
                        itemCount: game.cards.length,
                        gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 9,
                            crossAxisSpacing: 9,
                          ),
                        itemBuilder: (context, index) => _card(index),
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 9),
                Text(
                  game.complete
                      ? 'Excellent! You found all three trios.'
                      : 'Pick 3 cards. ${game.selected.length}/3 selected.',
                  style: const TextStyle(color: ink,
                      fontWeight: FontWeight.w900, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(
                    '${game.attempts} tries • ${game.mistakes} misses',
                    style: const TextStyle(
                      color: ink, fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  )),
                  FilledButton.icon(
                    key: const ValueKey('pattern-restart'),
                    onPressed: () => setState(() {
                      revision++;
                      _restart();
                    }),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7B78C6),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(game.complete ? 'PLAY AGAIN' : 'RESTART'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
