import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'match_three_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF1EA), surface: Colors.white, ink: Color(0xFF60494A),
  muted: Color(0xFF9B7D7C), accent: Color(0xFFE88367), edge: Color(0xFF60494A),
);
const _gems = [Color(0xFFE96F72), Color(0xFFF1B84D), Color(0xFF63B5A5),
  Color(0xFF6698D7), Color(0xFFAC7BC7)];

Widget buildMatchThreePage(BuildContext context, GameLaunch launch) =>
    MatchThreePage(launch: launch);

class MatchThreePage extends StatefulWidget {
  const MatchThreePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<MatchThreePage> createState() => _MatchThreePageState();
}

class _MatchThreePageState extends State<MatchThreePage> with LevelFlow<MatchThreePage> {
  late MatchThreeEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = MatchThreeEngine.forLevel(level);

  void _tap(int cell) {
    final result = _engine.tap(cell);
    if (result == MatchMove.ignored) return;
    setState(() {});
    if (result == MatchMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == MatchMove.rejected) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Match Three', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 270 : 205))
        .clamp(240.0, 410.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'CLEARED', value: '${_engine.cleared}/${_engine.goal}', palette: _palette),
              StatChip(label: 'MOVES', value: '${_engine.movesLeft}', palette: _palette),
            ])),
          const SizedBox(height: 14),
          Container(width: side, height: side, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF4D6C9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: _engine.board.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MatchThreeEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final color = _engine.board[cell] < 0 ? Colors.transparent : _gems[_engine.board[cell]];
                final selected = _engine.selected == cell;
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported || _engine.isFailed ? null : () => _tap(cell),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : const Color(0xFFFFF8F3),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: selected ? _palette.accent : const Color(0xFFE7D7CF),
                          width: selected ? 2 : 1)),
                      child: _engine.board[cell] < 0 ? null : Center(
                        child: Container(width: side / 11, height: side / 11,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: .75), width: 2),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 5)])),
                      )),
                ));
              },
            )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.movesLeft >= 5 ? 3 : _engine.movesLeft >= 2 ? 2 : 1,
                detail: 'Cleared the gem target.', onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'MOVES USED',
                detail: 'Swap gems to clear the target.', onRetry: replayLevel))
          else
            const HintLine('SWAP TWO NEIGHBOURING GEMS TO MATCH 3+', palette: _palette),
        ]));
    }),
  );
}
