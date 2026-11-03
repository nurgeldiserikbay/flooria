import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'nonogram_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF1EFF9), surface: Colors.white, ink: Color(0xFF49445F),
  muted: Color(0xFF8A849F), accent: Color(0xFF8574C7), edge: Color(0xFF49445F),
);

Widget buildNonogramPage(BuildContext context, GameLaunch launch) =>
    NonogramPage(launch: launch);

class NonogramPage extends StatefulWidget {
  const NonogramPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<NonogramPage> createState() => _NonogramPageState();
}

class _NonogramPageState extends State<NonogramPage> with LevelFlow<NonogramPage> {
  late NonogramEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = NonogramEngine.forLevel(level);

  void _tap(int cell) {
    final result = _engine.tapCell(cell);
    if (result == NonogramMark.ignored) return;
    setState(() {});
    if (result == NonogramMark.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Nonogram',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final cell = min((constraints.maxWidth - 78) / NonogramEngine.side,
        (constraints.maxHeight - (reported ? 225 : 155) - 62) / NonogramEngine.side)
        .clamp(34.0, 52.0).toDouble();
      final boardSide = cell * NonogramEngine.side;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'FILLED', value: '${_engine.marks.where((mark) => mark == 1).length}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 44),
            SizedBox(width: boardSide, height: 56,
              child: Row(children: [for (final clue in _engine.columnClues)
                Expanded(child: Center(child: Text(clue.join(' '), textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.clip,
                  style: TextStyle(color: _palette.muted, fontSize: 10,
                    height: 1.05, fontWeight: FontWeight.w900))))]),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 44,
              child: Column(children: [for (final clue in _engine.rowClues)
                SizedBox(height: cell, child: Align(alignment: Alignment.centerRight,
                  child: Padding(padding: const EdgeInsets.only(right: 5),
                    child: Text(clue.join(' '), textAlign: TextAlign.right,
                      style: TextStyle(color: _palette.muted, fontSize: 10,
                        fontWeight: FontWeight.w900)))))])),
            Container(width: boardSide, height: boardSide, padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: const Color(0xFFD8D2E7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _palette.edge, width: 2)),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _engine.marks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: NonogramEngine.side, crossAxisSpacing: 2, mainAxisSpacing: 2),
                itemBuilder: (context, cellIndex) {
                  final mark = _engine.marks[cellIndex];
                  return Material(color: Colors.transparent,
                    child: InkWell(onTap: reported ? null : () => _tap(cellIndex),
                      borderRadius: BorderRadius.circular(3),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(color: mark == 1
                          ? const Color(0xFF8574C7) : const Color(0xFFFBFAFE),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFFD2CDE2))),
                        child: mark == 2 ? const Icon(Icons.close_rounded,
                          size: 17, color: Color(0xFFAAA4BD)) : null,
                      )),
                  );
                },
              )),
          ]),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 24 ? 3 : 2,
                detail: 'The row and column clues all match.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('FILL THE CELLS TO MATCH EVERY CLUE', palette: _palette),
        ]));
    }),
  );
}
