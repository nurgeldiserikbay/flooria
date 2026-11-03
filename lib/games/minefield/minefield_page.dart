import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'minefield_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE9F3F7), surface: Colors.white, ink: Color(0xFF344B58),
  muted: Color(0xFF7C929B), accent: Color(0xFF4D9CAF), edge: Color(0xFF344B58),
);

Widget buildMinefieldPage(BuildContext context, GameLaunch launch) =>
    MinefieldPage(launch: launch);

class MinefieldPage extends StatefulWidget {
  const MinefieldPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<MinefieldPage> createState() => _MinefieldPageState();
}

class _MinefieldPageState extends State<MinefieldPage> with LevelFlow<MinefieldPage> {
  late MinefieldEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = MinefieldEngine.forLevel(level);

  void _reveal(int cell) {
    final result = _engine.revealCell(cell);
    if (result == MineAction.ignored) return;
    setState(() {});
    if (result == MineAction.won) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == MineAction.hit) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _flag(int cell) {
    if (_engine.toggleFlag(cell) == MineAction.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Minefield',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 26,
        constraints.maxHeight - (reported || _engine.isFailed ? 245 : 175))
        .clamp(270.0, 410.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'MINES', value: '${_engine.flags.length}/${_engine.mineCount}', palette: _palette),
                StatChip(label: 'SAFE', value: '${_engine.revealed.length}/${_engine.safeCount}', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Container(width: side, height: side, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFB9CED6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: MinefieldEngine.cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MinefieldEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final opened = _engine.revealed.contains(cell);
                final flagged = _engine.flags.contains(cell);
                final isMine = _engine.mines.contains(cell);
                final visibleMine = isMine && (_engine.isFailed || _engine.isCompleted);
                final clue = _engine.clues[cell];
                return Material(color: Colors.transparent,
                  child: InkWell(
                    onTap: reported || _engine.isFailed ? null : () => _reveal(cell),
                    onLongPress: reported || _engine.isFailed ? null : () => _flag(cell),
                    borderRadius: BorderRadius.circular(5),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: opened ? const Color(0xFFE7EFF1)
                          : flagged ? const Color(0xFFFFE2A2)
                          : visibleMine ? const Color(0xFFF2B4A9)
                          : const Color(0xFF6FA9B8),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: opened ? const Color(0xFFD0DDE1)
                          : const Color(0xFF4E8694), width: 1)),
                      child: Center(child: flagged
                        ? const Icon(Icons.flag_rounded, size: 18, color: Color(0xFFC27831))
                        : visibleMine
                          ? const Icon(Icons.circle, size: 16, color: Color(0xFFB44848))
                          : opened && clue > 0
                            ? Text('$clue', style: TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w900, color: _clueColor(clue)))
                            : null),
                    )),
                );
              },
            )),
          const SizedBox(height: 12),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.flags.length <= _engine.mineCount ? 3 : 2,
                detail: 'Every safe tile is revealed.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'MINE FOUND',
                detail: 'Watch the number clues and try again.', onRetry: replayLevel))
          else
            const HintLine('TAP TO REVEAL · HOLD TO FLAG', palette: _palette),
        ]));
    }),
  );

  Color _clueColor(int clue) => switch (clue) {
    1 => const Color(0xFF3977C5),
    2 => const Color(0xFF4C9362),
    3 => const Color(0xFFC24D4D),
    4 => const Color(0xFF7155A3),
    _ => const Color(0xFF455A64),
  };
}
