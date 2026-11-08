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
  int _blockedPulse = 0;
  String _feedback = 'JUMP OVER A PEG TO REMOVE IT';

  bool _isLegalDestination(int index) {
    final source = _engine.selectedCell;
    if (source == null || _engine.board[index] != 0 ||
        !PegSolitaireEngine.isValidCell(index)) {
      return false;
    }
    final sr = source ~/ PegSolitaireEngine.side;
    final sc = source % PegSolitaireEngine.side;
    final tr = index ~/ PegSolitaireEngine.side;
    final tc = index % PegSolitaireEngine.side;
    if (!((sr == tr && (sc - tc).abs() == 2) ||
        (sc == tc && (sr - tr).abs() == 2))) {
      return false;
    }
    final mid = ((sr + tr) ~/ 2) * PegSolitaireEngine.side +
        (sc + tc) ~/ 2;
    return _engine.board[mid] == 1;
  }

  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = PegSolitaireEngine.forLevel(level);
    _blockedPulse = 0;
    _feedback = 'JUMP OVER A PEG TO REMOVE IT';
  }

  void _tap(int index) {
    final result = _engine.tap(index);
    if (result == PegMove.ignored) {
      // Tapping the selected peg deselects it; repaint immediately.
      setState(() => _feedback = _engine.selectedCell == null
          ? 'SELECTION CLEARED · CHOOSE A PEG'
          : 'CHOOSE A PEG FIRST');
      return;
    }
    setState(() {
      if (result == PegMove.blocked) _blockedPulse++;
      _feedback = switch (result) {
        PegMove.selected => 'PEG SELECTED · TAP A HIGHLIGHTED LANDING',
        PegMove.blocked => 'NOT A LEGAL JUMP · HOP OVER ONE PEG',
        PegMove.moved => 'GREAT JUMP · ${_engine.pegCount} PEGS LEFT',
        PegMove.completed => 'ONLY ONE PEG LEFT · PUZZLE SOLVED!',
        PegMove.failed => 'NO JUMPS LEFT · TRY A NEW ROUTE',
        PegMove.ignored => _feedback,
      };
    });
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
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final motion = reducedMotion
          ? Duration.zero : const Duration(milliseconds: 175);
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
          Semantics(
            key: const ValueKey('peg-board-state'),
            label: '${_engine.pegCount} pegs remaining. '
                '${_engine.moves} jumps made. '
                '${_engine.selectedCell == null ? 'No peg selected' : 'Peg selected at row ${_engine.selectedCell! ~/ PegSolitaireEngine.side + 1}, column ${_engine.selectedCell! % PegSolitaireEngine.side + 1}'}.',
            child: Container(
            width: side, height: side,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFD7E9DA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFAACDB5)),
              boxShadow: const [
                BoxShadow(color: Color(0x26315845),
                  blurRadius: 16, offset: Offset(0, 5)),
              ],
            ),
            child: GridView.builder(
              key: const ValueKey('peg-board'),
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: PegSolitaireEngine.side * PegSolitaireEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: PegSolitaireEngine.side,
                crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, index) {
                if (!PegSolitaireEngine.isValidCell(index)) {
                  return const SizedBox.shrink();
                }
                final selected = _engine.selectedCell == index;
                final occupied = _engine.board[index] == 1;
                final destination = _isLegalDestination(index);
                return Semantics(
                  key: ValueKey('peg-cell-$index'),
                  button: true,
                  enabled: !reported && !_engine.isFailed,
                  selected: selected,
                  label: 'Row ${index ~/ PegSolitaireEngine.side + 1}, '
                      'column ${index % PegSolitaireEngine.side + 1}, '
                      '${occupied ? 'peg' : 'empty hole'}'
                      '${selected ? ', selected' : ''}'
                      '${destination ? ', legal landing' : ''}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: reported || _engine.isFailed
                          ? null : () => _tap(index),
                      borderRadius: BorderRadius.circular(9),
                      child: AnimatedScale(
                        scale: selected ? .94 : 1,
                        duration: motion,
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: motion,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: selected
                                  ? const [Color(0xFFFFEAAF), Color(0xFFFFD46B)]
                                  : destination
                                      ? const [
                                          Color(0xFFF1FFF2),
                                          Color(0xFFBBE7CA),
                                        ]
                                      : occupied
                                          ? const [
                                              Color(0xFFC9EACA),
                                              Color(0xFF89C69B),
                                            ]
                                          : const [
                                              Color(0xFFEFF7EF),
                                              Color(0xFFD9E9DC),
                                            ],
                            ),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFD29F40)
                                  : destination
                                      ? const Color(0xFF53A875)
                                      : const Color(0xFFB6CEBA),
                              width: selected || destination ? 2 : 1,
                            ),
                            boxShadow: destination ? const [
                              BoxShadow(color: Color(0x3553A875),
                                blurRadius: 8, offset: Offset(0, 2)),
                            ] : null,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: motion,
                              child: occupied
                                  ? Container(
                                      key: const ValueKey('peg-piece'),
                                      width: side / 15,
                                      height: side / 15,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: selected
                                              ? const [
                                                  Color(0xFFA78339),
                                                  Color(0xFF795323),
                                                ]
                                              : const [
                                                  Color(0xFF5D9C70),
                                                  Color(0xFF315845),
                                                ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x44315845),
                                            blurRadius: 5,
                                            offset: Offset(0, 2)),
                                        ],
                                      ),
                                    )
                                  : Icon(
                                      destination
                                          ? Icons.radio_button_unchecked_rounded
                                          : Icons.circle_outlined,
                                      key: ValueKey('peg-empty-$destination'),
                                      color: destination
                                          ? const Color(0xFF53A875)
                                          : const Color(0x6682A58C),
                                      size: destination ? 21 : 13,
                                    ),
                            ),
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
                level: level, stars: _engine.moves <= 7 + level ? 3 : 2,
                detail: 'Reduced the board to one peg.', onReplay: replayLevel,
                onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'NO MOVES LEFT',
                detail: 'Start again and plan each jump.', onRetry: replayLevel))
          else
            Shake(
              trigger: _blockedPulse,
              child: HintLine(_feedback, palette: _palette),
            ),
        ]));
    }),
  );
}
