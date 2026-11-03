import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'knight_tour_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF1F0E9), surface: Colors.white, ink: Color(0xFF4C493E),
  muted: Color(0xFF8B8779), accent: Color(0xFFB58A4D), edge: Color(0xFF4C493E),
);

Widget buildKnightTourPage(BuildContext context, GameLaunch launch) =>
    KnightTourPage(launch: launch);

class KnightTourPage extends StatefulWidget {
  const KnightTourPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<KnightTourPage> createState() => _KnightTourPageState();
}

class _KnightTourPageState extends State<KnightTourPage> with LevelFlow<KnightTourPage> {
  late KnightTourEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = KnightTourEngine.forLevel(level);

  void _move(int cell) {
    final result = _engine.move(cell);
    if (result == KnightMove.ignored || result == KnightMove.blocked) {
      if (result == KnightMove.blocked) HapticFeedback.selectionClick();
      return;
    }
    setState(() {});
    if (result == KnightMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: "Knight's Tour",
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final board = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported ? 240 : 165)).clamp(245.0, 430.0).toDouble();
      final legal = _engine.availableMoves;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'VISITED', value: '${_engine.visited.length}/${_engine.goal}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.path.length - 1}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Container(width: board, height: board, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFD7CFBD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.goal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _engine.size, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final row = cell ~/ _engine.size, col = cell % _engine.size;
                final isLight = (row + col).isEven;
                final current = _engine.current == cell;
                final visited = _engine.visited.contains(cell);
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _move(cell),
                    borderRadius: BorderRadius.circular(5),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 110),
                      decoration: BoxDecoration(color: current
                        ? const Color(0xFFFFD66E)
                        : visited ? const Color(0xFF88B890)
                        : legal.contains(cell) ? const Color(0xFFB7D8AA)
                        : isLight ? const Color(0xFFF2E9D8) : const Color(0xFF9EAD9B),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: current ? _palette.edge
                          : const Color(0x55706A5D), width: current ? 2 : 1)),
                      child: current ? Text('♞', style: TextStyle(
                        fontSize: board / _engine.size * .58, color: _palette.ink,
                        fontWeight: FontWeight.w900))
                        : visited ? const Icon(Icons.circle, size: 7, color: Colors.white)
                        : legal.contains(cell) ? const Icon(Icons.circle, size: 9,
                          color: Color(0xFF5E9B64)) : null,
                    )),
                );
              },
            )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: 3, detail: 'Every square visited exactly once.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('USE KNIGHT MOVES · NEVER REVISIT A SQUARE', palette: _palette),
        ]));
    }),
  );
}
