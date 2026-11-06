import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'tangram_fit_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF3E5), surface: Colors.white, ink: Color(0xFF654D3A),
  muted: Color(0xFF9B816B), accent: Color(0xFFD88A45), edge: Color(0xFF654D3A),
);
const _pieceColors = [
  Color(0xFF64A9D8), Color(0xFF79B88B), Color(0xFFE6AE4E), Color(0xFFCB7FB5),
];

Widget buildTangramFitPage(BuildContext context, GameLaunch launch) =>
    TangramFitPage(launch: launch);

class TangramFitPage extends StatefulWidget {
  const TangramFitPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<TangramFitPage> createState() => _TangramFitPageState();
}

class _TangramFitPageState extends State<TangramFitPage>
    with LevelFlow<TangramFitPage> {
  late TangramFitEngine _engine;
  int _blockedPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = TangramFitEngine.forLevel(level);
    _blockedPulse = 0;
  }

  void _select(int piece) {
    setState(() => _engine.selectPiece(piece));
    HapticFeedback.selectionClick();
  }

  void _rotate() {
    if (_engine.rotateSelected() == TangramMove.ignored) return;
    setState(() {});
    HapticFeedback.lightImpact();
  }

  void _place(int cell) {
    final result = _engine.placeSelected(cell);
    if (result == TangramMove.ignored) return;
    if (result == TangramMove.blocked) {
      HapticFeedback.selectionClick();
      setState(() => _blockedPulse++);
      return;
    }
    setState(() {});
    if (result == TangramMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Tangram Fit',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final boardSize = min(constraints.maxWidth - 30,
        constraints.maxHeight - (reported ? 330 : 250))
        .clamp(220.0, 360.0).toDouble();
      final cellSize = boardSize / TangramFitEngine.side;
      final placed = <int, int>{};
      for (var piece = 0; piece < 4; piece++) {
        for (final cell in _engine.cellsOf(piece)) { placed[cell] = piece; }
      }
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'PIECES', value: '${_engine.placedCount}/4', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Shake(
            trigger: _blockedPulse,
            child: Container(
              width: boardSize, height: boardSize,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8E7D0), Color(0xFFE1C8A9)],
                ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: TangramFitEngine.side * TangramFitEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: TangramFitEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final piece = placed[cell];
                final target = _engine.targetCells.contains(cell);
                final color = piece == null
                    ? (target ? const Color(0xFFFFE5B8)
                        : const Color(0xFFF8F5F0))
                    : _pieceColors[piece];
                final reduceMotion =
                    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                return Semantics(
                  button: true,
                  label: piece != null ? 'Placed piece'
                      : target ? 'Target cell' : 'Empty cell',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('tangram-cell-$cell'),
                      onTap: reported ? null : () => _place(cell),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 190),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, .26)!,
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: target ? const Color(0xFFD5A56E)
                                : const Color(0xFFE5DCD2),
                            width: target ? 1.7 : 1,
                          ),
                          boxShadow: piece == null ? null : [
                            BoxShadow(
                              color: GamePalette.shade(color, .25)
                                  .withValues(alpha: .6),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 190),
                          switchInCurve: Curves.easeOutBack,
                          child: piece == null
                              ? const SizedBox.shrink(
                                  key: ValueKey('blank'))
                              : Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('placed-$piece'),
                                  size: cellSize * .48,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: 12),
          if (!reported)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var piece = 0; piece < 4; piece++) ...[
                if (piece > 0) const SizedBox(width: 8),
                _PieceButton(
                  key: ValueKey('tangram-piece-$piece'),
                  piece: piece, selected: _engine.selectedPiece == piece,
                  placed: _engine.anchorOf(piece) != null,
                  color: _pieceColors[piece], shape: _engine.shapeCells(piece),
                  onTap: () => _select(piece)),
              ],
              const SizedBox(width: 8),
              ChunkyIconButton(icon: Icons.rotate_right_rounded, tooltip: 'Rotate piece',
                palette: _palette, onPressed: _engine.selectedPiece == null ? null : _rotate,
                size: 42),
            ]),
          const SizedBox(height: 10),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 8 ? 3 : _engine.moves <= 12 ? 2 : 1,
                detail: 'Filled the silhouette with all four pieces.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('SELECT A PIECE · ROTATE · TAP ITS TOP LEFT CELL', palette: _palette),
        ]));
    }),
  );
}

class _PieceButton extends StatelessWidget {
  const _PieceButton({super.key, required this.piece, required this.selected,
    required this.placed, required this.color, required this.shape,
    required this.onTap});
  final int piece;
  final bool selected;
  final bool placed;
  final Color color;
  final List<Point<int>> shape;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedScale(
      scale: selected ? 1.07 : 1,
      duration: reducedMotion
          ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: 46,
        height: 49,
        child: ChunkyButton(
          onPressed: placed ? null : onTap,
          color: selected ? color : Colors.white,
          edgeColor: selected ? GamePalette.shade(color) : _palette.edge,
          depth: 3,
          radius: 10,
          padding: EdgeInsets.zero,
          semanticLabel: 'Shape ${piece + 1}',
          child: placed
              ? Icon(Icons.check_rounded,
                  color: selected ? Colors.white : color, size: 23)
              : CustomPaint(
                  size: const Size(30, 30),
                  painter: _MiniShapePainter(
                    shape, selected ? Colors.white : color),
                ),
        ),
      ),
    );
  }
}

class _MiniShapePainter extends CustomPainter {
  const _MiniShapePainter(this.cells, this.color);
  final List<Point<int>> cells;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final extent = max(1, max(cells.map((cell) => cell.x).reduce(max),
      cells.map((cell) => cell.y).reduce(max)) + 1);
    final unit = size.shortestSide / extent;
    for (final cell in cells) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cell.x * unit + 1, cell.y * unit + 1, unit - 2, unit - 2),
        const Radius.circular(3)), Paint()..color = color);
    }
  }
  @override
  bool shouldRepaint(covariant _MiniShapePainter oldDelegate) =>
      oldDelegate.cells != cells || oldDelegate.color != color;
}
