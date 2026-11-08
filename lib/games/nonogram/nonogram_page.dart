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
  String _feedback = 'FILL CELLS TO MATCH EVERY ROW AND COLUMN CLUE';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = NonogramEngine.forLevel(level);
    _feedback = 'FILL CELLS TO MATCH EVERY ROW AND COLUMN CLUE';
  }

  void _tap(int cell) {
    final result = _engine.tapCell(cell);
    if (result == NonogramMark.ignored) return;
    setState(() {
      final mark = _engine.marks[cell];
      _feedback = result == NonogramMark.completed
          ? 'ALL CLUES MATCH · PICTURE COMPLETE!'
          : mark == 1
              ? 'CELL FILLED · CHECK THE ROW AND COLUMN CLUES'
              : mark == 2
                  ? 'CELL CROSSED · THIS SPACE STAYS EMPTY'
                  : 'CELL CLEARED · KEEP SOLVING THE PICTURE';
    });
    if (result == NonogramMark.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // A solved clue changes colour immediately; no extra numbers or banners
  // are needed, so the board stays the primary focus.
  bool _matchesClue(Iterable<int> marks, List<int> expected) {
    final actual = <int>[];
    var run = 0;
    for (final mark in marks) {
      if (mark == 1) {
        run++;
      } else if (run > 0) {
        actual.add(run);
        run = 0;
      }
    }
    if (run > 0) actual.add(run);
    if (actual.isEmpty) actual.add(0);
    if (actual.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }

  int get _solvedClues {
    var solved = 0;
    for (var row = 0; row < NonogramEngine.side; row++) {
      if (_matchesClue(
        _engine.marks.skip(row * NonogramEngine.side).take(NonogramEngine.side),
        _engine.rowClues[row],
      )) {
        solved++;
      }
    }
    for (var col = 0; col < NonogramEngine.side; col++) {
      if (_matchesClue(
        [for (var row = 0; row < NonogramEngine.side; row++)
          _engine.marks[row * NonogramEngine.side + col]],
        _engine.columnClues[col],
      )) {
        solved++;
      }
    }
    return solved;
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
                StatChip(label: 'CLUES', value: '$_solvedClues/12', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 44),
            SizedBox(width: boardSide, height: 56,
              child: Row(children: [
                for (var col = 0; col < _engine.columnClues.length; col++)
                  Expanded(child: Center(child: Text(
                    _engine.columnClues[col].join(' '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: _matchesClue(
                        [for (var row = 0; row < NonogramEngine.side; row++)
                          _engine.marks[row * NonogramEngine.side + col]],
                        _engine.columnClues[col],
                      ) ? _palette.accent : _palette.muted,
                      fontSize: 10, height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ))),
              ])),
          ]),
          Semantics(
            key: const ValueKey('nonogram-board-state'),
            label: '$_solvedClues of 12 row and column clues matched. '
                '${_engine.moves} moves made. '
                '${_engine.marks.where((mark) => mark == 1).length} cells filled.',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 44,
              child: Column(children: [
                for (var row = 0; row < _engine.rowClues.length; row++)
                  SizedBox(height: cell,
                    child: Align(alignment: Alignment.centerRight,
                      child: Padding(padding: const EdgeInsets.only(right: 5),
                        child: Text(_engine.rowClues[row].join(' '),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: _matchesClue(
                              _engine.marks.skip(row * NonogramEngine.side)
                                  .take(NonogramEngine.side),
                              _engine.rowClues[row],
                            ) ? _palette.accent : _palette.muted,
                            fontSize: 10, fontWeight: FontWeight.w900,
                          )),
                      ),
                    ),
                  ),
              ])),
            Container(width: boardSide, height: boardSide,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E2F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD3CBE7)),
                boxShadow: const [
                  BoxShadow(color: Color(0x2649445F),
                    blurRadius: 16, offset: Offset(0, 5)),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _engine.marks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: NonogramEngine.side, crossAxisSpacing: 2, mainAxisSpacing: 2),
                itemBuilder: (context, cellIndex) {
                  final mark = _engine.marks[cellIndex];
                  final reducedMotion =
                      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                  final duration = reducedMotion ? Duration.zero
                      : const Duration(milliseconds: 170);
                  return Semantics(
                    key: ValueKey('nonogram-cell-$cellIndex'),
                    button: true,
                    enabled: !reported,
                    label: 'Row ${cellIndex ~/ NonogramEngine.side + 1}, '
                        'column ${cellIndex % NonogramEngine.side + 1}, '
                        '${mark == 1 ? 'filled' : mark == 2 ? 'crossed' : 'empty'}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: reported ? null : () => _tap(cellIndex),
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedScale(
                          scale: mark == 1 ? .96 : 1,
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          child: AnimatedContainer(
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: mark == 1
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFB9A6EF),
                                        Color(0xFF7563BF),
                                      ],
                                    )
                                  : null,
                              color: mark == 1 ? null
                                  : mark == 2
                                      ? const Color(0xFFF1EDF7)
                                      : const Color(0xFFFBFAFE),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: mark == 1
                                    ? const Color(0xFF7563BF)
                                    : const Color(0xFFD8D2E8),
                              ),
                              boxShadow: mark == 1 ? const [
                                BoxShadow(
                                  color: Color(0x448574C7),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: mark == 2
                                ? const Icon(Icons.close_rounded,
                                    size: 17, color: Color(0xFFABA5BD))
                                : mark == 1
                                    ? const Center(child: Icon(
                                        Icons.circle, size: 7,
                                        color: Color(0x99FFFFFF)))
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )),
          ])),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 24 ? 3 : 2,
                detail: 'The row and column clues all match.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            HintLine(_feedback, palette: _palette),
        ]));
    }),
  );
}
