import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'number_maze_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEFF5EE), surface: Colors.white, ink: Color(0xFF3E5742),
  muted: Color(0xFF7F9380), accent: Color(0xFF63A96E), edge: Color(0xFF3E5742),
);

Widget buildNumberMazePage(BuildContext context, GameLaunch launch) =>
    NumberMazePage(launch: launch);

class NumberMazePage extends StatefulWidget {
  const NumberMazePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<NumberMazePage> createState() => _NumberMazePageState();
}

class _NumberMazePageState extends State<NumberMazePage> with LevelFlow<NumberMazePage> {
  late NumberMazeEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = NumberMazeEngine.forLevel(level);

  void _enter(int cell) {
    final result = _engine.enter(cell);
    if (result == MazeMove.ignored || result == MazeMove.blocked) {
      if (result == MazeMove.blocked) HapticFeedback.selectionClick();
      return;
    }
    setState(() {});
    if (result == MazeMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == MazeMove.failed) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Number Maze',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 260 : 190))
        .clamp(250.0, 420.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'ENERGY', value: '${_engine.energy}', palette: _palette),
                StatChip(label: 'STEPS', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Container(width: side, height: side, padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: const Color(0xFFC9D9C4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: NumberMazeEngine.side, crossAxisSpacing: 5, mainAxisSpacing: 5),
              itemBuilder: (context, cell) {
                final visited = _engine.path.contains(cell);
                final current = _engine.position == cell;
                final value = _engine.values[cell];
                final color = current ? const Color(0xFF77B7E6)
                  : visited ? const Color(0xFF8AC69A)
                  : value < 0 ? const Color(0xFFF1B8A8)
                  : value > 0 ? const Color(0xFFFFE39A) : const Color(0xFFF1F2E9);
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported || _engine.isFailed
                      ? null : () => _enter(cell),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: current ? _palette.edge
                          : const Color(0xFFB8C9B4), width: current ? 2 : 1)),
                      child: Center(child: cell == _engine.values.length - 1
                        ? const Icon(Icons.flag_rounded, color: Color(0xFF477F52), size: 25)
                        : Text(cell == 0 ? 'START' : '${value > 0 ? '+' : ''}$value',
                          style: TextStyle(color: _palette.ink,
                            fontSize: cell == 0 ? 10 : 19, fontWeight: FontWeight.w900))),
                    )),
                );
              },
            )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.energy >= 5 ? 3 : 2,
                detail: 'Reached the exit with ${_engine.energy} energy.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'OUT OF ENERGY',
                detail: 'Choose a safer route to the exit.', onRetry: replayLevel))
          else
            const HintLine('STEP ON + CELLS TO KEEP YOUR ENERGY', palette: _palette),
        ]));
    }),
  );
}
