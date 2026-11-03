import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'peg_solitaire_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF5EE), surface: Colors.white, ink: Color(0xFF315845),
  muted: Color(0xFF789483), accent: Color(0xFF4DA875), edge: Color(0xFF315845),
);

Widget buildPegSolitairePage(BuildContext context, GameLaunch launch) =>
    PegSolitairePage(launch: launch);

class PegSolitairePage extends StatefulWidget {
  const PegSolitairePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<PegSolitairePage> createState() => _PegSolitairePageState();
}

class _PegSolitairePageState extends State<PegSolitairePage>
    with LevelFlow<PegSolitairePage> {
  late PegSolitaireEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = PegSolitaireEngine.forLevel(level);

  void _tap(int index) {
    final result = _engine.tap(index);
    if (result == PegMove.ignored) return;
    setState(() {});
    if (result == PegMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: {'remainingPegs': _engine.pegCount});
    } else if (result == PegMove.moved) {
      HapticFeedback.lightImpact();
    } else if (result == PegMove.blocked || result == PegMove.failed) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Peg Solitaire',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 26,
        constraints.maxHeight - (reported || _engine.isFailed ? 275 : 190))
        .clamp(245.0, 430.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'PEGS', value: '${_engine.pegCount}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Container(width: side, height: side, padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: const Color(0xFFC7DEC9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: PegSolitaireEngine.side * PegSolitaireEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: PegSolitaireEngine.side,
                crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, index) {
                if (!PegSolitaireEngine.isValidCell(index)) return const SizedBox();
                final selected = _engine.selectedCell == index;
                final occupied = _engine.board[index] == 1;
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _tap(index),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFD66B)
                          : occupied ? const Color(0xFF75B989) : const Color(0xFFDDEBDD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? _palette.edge
                          : const Color(0xFFB7D0B9), width: selected ? 2 : 1)),
                      child: occupied ? Center(child: Container(
                        width: side / 15, height: side / 15,
                        decoration: BoxDecoration(color: selected
                          ? const Color(0xFF8A6422) : const Color(0xFF315845),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x44315845),
                            offset: Offset(0, 2))]))) : null,
                    )),
                );
              },
            )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 7 + level ? 3 : 2,
                detail: 'Reduced the board to one peg.', onReplay: replayLevel,
                onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'NO MOVES LEFT',
                detail: 'Start again and plan each jump.', onRetry: replayLevel))
          else
            const HintLine('JUMP OVER A PEG TO REMOVE IT', palette: _palette),
        ]));
    }),
  );
}
