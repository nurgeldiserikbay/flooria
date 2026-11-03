import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'color_flood_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF6F1E8), surface: Colors.white, ink: Color(0xFF4B453C),
  muted: Color(0xFF918577), accent: Color(0xFF6F9E86), edge: Color(0xFF4B453C),
);
const _floodColors = [
  Color(0xFFE77768), Color(0xFFEDB94F), Color(0xFF70B98A),
  Color(0xFF64A9D5), Color(0xFF9A7BC4), Color(0xFFE17CA9),
];

Widget buildColorFloodPage(BuildContext context, GameLaunch launch) =>
    ColorFloodPage(launch: launch);

class ColorFloodPage extends StatefulWidget {
  const ColorFloodPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<ColorFloodPage> createState() => _ColorFloodPageState();
}

class _ColorFloodPageState extends State<ColorFloodPage> with LevelFlow<ColorFloodPage> {
  late ColorFloodEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = ColorFloodEngine.forLevel(level);

  void _choose(int color) {
    final result = _engine.chooseColor(color);
    if (result == FloodMove.ignored) return;
    setState(() {});
    if (result == FloodMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == FloodMove.failed) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Color Flood',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 280 : 230))
        .clamp(235.0, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'CLAIMED', value: '${_engine.claimedCount}/${_engine.board.length}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}/${_engine.moveLimit}', palette: _palette),
              ])),
          const SizedBox(height: 13),
          Container(width: side, height: side, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFDED7CB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.board.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ColorFloodEngine.side, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemBuilder: (context, cell) => AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                decoration: BoxDecoration(color: _floodColors[_engine.colorAt(cell)],
                  borderRadius: BorderRadius.circular(3)),
              ),
            )),
          const SizedBox(height: 14),
          if (!reported && !_engine.isFailed)
            Wrap(alignment: WrapAlignment.center, spacing: 9, runSpacing: 8,
              children: [for (var color = 0; color < _engine.colorCount; color++)
                _ColorChoice(color: _floodColors[color], selected: _engine.currentColor == color,
                  onTap: () => _choose(color))]),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= _engine.moveLimit - 5 ? 3 : 2,
                detail: 'The colour region covered every tile.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'MOVE LIMIT REACHED',
                detail: 'Try a different colour order.', onRetry: replayLevel))
          else
            const HintLine('CHOOSE COLOURS TO FILL THE WHOLE BOARD', palette: _palette),
        ]));
    }),
  );
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: selected ? 'Current colour' : 'Choose colour',
    child: GestureDetector(onTap: selected ? null : onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 130),
        width: 42, height: 42,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: selected ? _palette.ink : Colors.white, width: selected ? 3 : 2),
          boxShadow: [BoxShadow(color: GamePalette.shade(color, .25), offset: const Offset(0, 3))]),
        child: selected ? const Icon(Icons.check_rounded, size: 20, color: Colors.white) : null,
      )),
  );
}
