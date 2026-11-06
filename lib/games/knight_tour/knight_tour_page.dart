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
          Container(
            width: board,
            height: board,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEDE5D4), Color(0xFFC8BDA8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [
                BoxShadow(color: _palette.edge.withValues(alpha: .55),
                  offset: const Offset(0, 5)),
              ],
            ),
            child: LayoutBuilder(builder: (context, bounds) {
              const gap = 3.0;
              final cellSize = (bounds.maxWidth
                  - gap * (_engine.size - 1)) / _engine.size;
              final stride = cellSize + gap;
              final reducedMotion =
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              return Stack(children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _engine.goal,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _engine.size,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                  ),
                  itemBuilder: (context, cell) {
                    final row = cell ~/ _engine.size;
                    final col = cell % _engine.size;
                    final isLight = (row + col).isEven;
                    final current = _engine.current == cell;
                    final visited = _engine.visited.contains(cell);
                    final available = legal.contains(cell);
                    return Semantics(
                      button: available,
                      label: current ? 'Knight' : visited ? 'Visited square'
                          : available ? 'Possible knight move' : 'Square',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('knight-cell-$cell'),
                          onTap: reported ? null : () => _move(cell),
                          borderRadius: BorderRadius.circular(5),
                          child: AnimatedContainer(
                            duration: reducedMotion ? Duration.zero
                                : const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: current
                                    ? [const Color(0xFFFFF0A8),
                                        const Color(0xFFF9C85E)]
                                    : visited
                                        ? [const Color(0xFFC0DFC0),
                                            const Color(0xFF8DBD94)]
                                        : available
                                            ? [const Color(0xFFE1F3D2),
                                                const Color(0xFFB6DDAA)]
                                            : isLight
                                                ? [const Color(0xFFFFF9E9),
                                                    const Color(0xFFF0E4CF)]
                                                : [const Color(0xFFC7D0B8),
                                                    const Color(0xFFA0B29D)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: current
                                  ? _palette.edge
                                  : const Color(0x55706A5D),
                                  width: current ? 2 : 1),
                            ),
                            alignment: Alignment.center,
                            child: current ? null
                                : visited
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : available
                                        ? const Icon(
                                            Icons.radio_button_checked_rounded,
                                            size: 15, color: Color(0xFF5E9B64))
                                        : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedPositioned(
                  duration: reducedMotion ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  left: (_engine.current % _engine.size) * stride,
                  top: (_engine.current ~/ _engine.size) * stride,
                  width: cellSize,
                  height: cellSize,
                  child: IgnorePointer(
                    child: Center(child: Text(
                      '♞',
                      key: const ValueKey('knight-piece'),
                      style: TextStyle(
                        fontSize: cellSize * .66,
                        height: 1,
                        color: _palette.ink,
                        shadows: const [
                          Shadow(color: Color(0x99524330),
                            offset: Offset(1, 3), blurRadius: 2),
                        ],
                      ),
                    )),
                  ),
                ),
              ]);
            }),
          ),
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
