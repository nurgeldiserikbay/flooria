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
  int _blockedPulse = 0;
  String _feedback = 'STEP ON + CELLS TO KEEP YOUR ENERGY';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = NumberMazeEngine.forLevel(level);
    _blockedPulse = 0;
    _feedback = 'STEP ON + CELLS TO KEEP YOUR ENERGY';
  }

  void _enter(int cell) {
    final before = _engine.energy;
    final result = _engine.enter(cell);
    if (result == MazeMove.ignored) return;
    if (result == MazeMove.blocked) {
      HapticFeedback.selectionClick();
      setState(() {
        _blockedPulse++;
        _feedback = 'MOVE ONE SPACE · AVOID VISITED CELLS';
      });
      return;
    }
    setState(() {
      _feedback = result == MazeMove.completed
          ? 'EXIT REACHED · GREAT WORK!'
          : result == MazeMove.failed
              ? 'OUT OF ENERGY · TRY A SAFER ROUTE'
              : _engine.energy > before
                  ? 'ENERGY +${_engine.energy - before} · KEEP GOING'
                  : _engine.energy < before
                      ? 'ENERGY ${_engine.energy - before} · WATCH YOUR STEPS'
                      : 'ENERGY STEADY · FIND THE EXIT';
    });
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
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration = reducedMotion
          ? Duration.zero : const Duration(milliseconds: 160);
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
          Semantics(
            key: const ValueKey('number-maze-progress'),
            label: 'Energy ${_engine.energy}. ${_engine.moves} steps taken. '
                'Player at row ${_engine.position ~/ NumberMazeEngine.side + 1}, '
                'column ${_engine.position % NumberMazeEngine.side + 1}. '
                'Reach the exit on the bottom right.',
            child: Container(
            width: side, height: side,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E5D3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA8C5A6)),
              boxShadow: const [
                BoxShadow(color: Color(0x273E5742),
                  blurRadius: 16, offset: Offset(0, 5)),
              ],
            ),
            child: GridView.builder(
              key: const ValueKey('number-maze-board'),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: NumberMazeEngine.side,
                crossAxisSpacing: 5, mainAxisSpacing: 5),
              itemBuilder: (context, cell) {
                final visited = _engine.path.contains(cell);
                final current = _engine.position == cell;
                final value = _engine.values[cell];
                final row = cell ~/ NumberMazeEngine.side;
                final col = cell % NumberMazeEngine.side;
                final playerRow =
                    _engine.position ~/ NumberMazeEngine.side;
                final playerCol =
                    _engine.position % NumberMazeEngine.side;
                final available = !visited &&
                    (row - playerRow).abs() +
                        (col - playerCol).abs() == 1;
                final goal = cell == _engine.values.length - 1;
                final color = current
                    ? const Color(0xFF9BC9EE)
                    : visited
                        ? const Color(0xFFB4DDC1)
                        : value < 0
                            ? const Color(0xFFFFD1C1)
                            : value > 0
                                ? const Color(0xFFFFE9A9)
                                : const Color(0xFFF9FAF4);
                return Semantics(
                  key: ValueKey('maze-cell-$cell'),
                  button: true,
                  enabled: !reported && !_engine.isFailed,
                  label: 'Row ${row + 1}, column ${col + 1}, '
                      '${goal ? 'exit' : cell == 0 ? 'start' : 'value $value'}'
                      '${current ? ', current position' : ''}'
                      '${visited ? ', visited' : ''}'
                      '${available ? ', available next step' : ''}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: reported || _engine.isFailed
                          ? null : () => _enter(cell),
                      borderRadius: BorderRadius.circular(9),
                      child: AnimatedScale(
                        duration: duration,
                        scale: available ? 1 : .975,
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: current
                                  ? const Color(0xFF397EBA)
                                  : available
                                      ? const Color(0xFF7BAC7B)
                                      : const Color(0xFFB8C9B4),
                              width: current || available ? 2 : 1,
                            ),
                            boxShadow: available ? const [
                              BoxShadow(color: Color(0x247BAC7B),
                                blurRadius: 7, offset: Offset(0, 2)),
                            ] : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              goal
                                  ? const Icon(Icons.flag_rounded,
                                      color: Color(0xFF477F52), size: 25)
                                  : Text(cell == 0 ? 'START'
                                      : '${value > 0 ? '+' : ''}$value',
                                      style: TextStyle(
                                        color: _palette.ink,
                                        fontSize: cell == 0 ? 10 : 19,
                                        fontWeight: FontWeight.w900,
                                      )),
                              if (current)
                                const Positioned(
                                  top: 1, right: 1,
                                  child: Icon(Icons.circle,
                                    size: 9, color: Color(0xFF397EBA)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
            Shake(
              trigger: _blockedPulse,
              child: HintLine(_feedback, palette: _palette),
            ),
        ]));
    }),
  );
}
