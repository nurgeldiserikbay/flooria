import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'gravity_shift_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF0EEFF), surface: Colors.white, ink: Color(0xFF4D4B70),
  muted: Color(0xFF8583A8), accent: Color(0xFF8279D8), edge: Color(0xFF4D4B70),
);

Widget buildGravityShiftPage(BuildContext context, GameLaunch launch) =>
    GravityShiftPage(launch: launch);

class GravityShiftPage extends StatefulWidget {
  const GravityShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<GravityShiftPage> createState() => _GravityShiftPageState();
}

class _GravityShiftPageState extends State<GravityShiftPage> with LevelFlow<GravityShiftPage> {
  late GravityShiftEngine _engine;
  int _blockedPulse = 0;
  String _feedback = 'TILT GRAVITY · USE WALLS TO CHANGE COURSE';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = GravityShiftEngine.forLevel(level);
    _blockedPulse = 0;
    _feedback = 'TILT GRAVITY · USE WALLS TO CHANGE COURSE';
  }

  void _tilt(GravityDirection direction) {
    final result = _engine.tilt(direction);
    if (result == GravityMove.ignored || result == GravityMove.blocked) {
      if (result == GravityMove.blocked) {
        HapticFeedback.selectionClick();
        setState(() {
          _blockedPulse++;
          _feedback = 'NO ROOM TO ROLL · TRY ANOTHER DIRECTION';
        });
      }
      return;
    }
    setState(() {
      _feedback = result == GravityMove.completed
          ? 'EXIT REACHED · GREAT JOB!'
          : _engine.movesLeft <= 2
              ? 'ALMOST OUT OF MOVES · PLAN THE NEXT TILT'
              : 'GOOD ROLL · USE THE WALLS TO STOP';
    });
    if (result == GravityMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Gravity Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 32,
        constraints.maxHeight - (reported || _engine.isFailed ? 300 : 235))
        .clamp(230.0, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'MOVES LEFT', value: '${_engine.movesLeft}', palette: _palette),
              StatChip(label: 'WALLS', value: '${_engine.walls.length}', palette: _palette),
            ])),
          const SizedBox(height: 14),
          Semantics(
            key: const ValueKey('gravity-board-state'),
            label: 'Ball at row ${_engine.ball ~/ GravityShiftEngine.side + 1}, '
                'column ${_engine.ball % GravityShiftEngine.side + 1}. '
                '${_engine.movesLeft} moves remaining. '
                'Goal at row ${_engine.goal ~/ GravityShiftEngine.side + 1}, '
                'column ${_engine.goal % GravityShiftEngine.side + 1}.',
            child: Shake(
            trigger: _blockedPulse,
            child: Container(
              width: side,
              height: side,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAE8FF), Color(0xFFC7C4EB)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _palette.edge, width: 2),
                boxShadow: [
                  BoxShadow(color: _palette.edge.withValues(alpha: .55),
                    offset: const Offset(0, 5)),
                ],
              ),
              child: LayoutBuilder(builder: (context, boardBounds) {
                const sideCount = GravityShiftEngine.side;
                const gap = 4.0;
                final cellSide =
                    (boardBounds.maxWidth - gap * (sideCount - 1)) / sideCount;
                final cellStep = cellSide + gap;
                final reducedMotion =
                    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                return Stack(children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: sideCount * sideCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: sideCount,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                    ),
                    itemBuilder: (context, cell) {
                      final wall = _engine.walls.contains(cell);
                      final goal = _engine.goal == cell;
                      return Container(
                        key: ValueKey('gravity-cell-$cell'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: wall
                                ? [
                                    const Color(0xFF8D8BAD),
                                    const Color(0xFF67648F),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFE9E8FA),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: wall ? _palette.edge
                                : const Color(0xFFDDDCF0),
                          ),
                        ),
                        child: Center(child: wall
                            ? const Icon(Icons.square_rounded,
                                size: 12, color: Color(0xFFB0AEC9))
                            : goal
                                ? const Icon(Icons.flag_rounded,
                                    color: Color(0xFF67AE83))
                                : null),
                      );
                    },
                  ),
                  AnimatedPositioned(
                    duration: reducedMotion
                        ? Duration.zero : const Duration(milliseconds: 210),
                    curve: Curves.easeInOutCubic,
                    left: (_engine.ball % sideCount) * cellStep,
                    top: (_engine.ball ~/ sideCount) * cellStep,
                    width: cellSide,
                    height: cellSide,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          key: const ValueKey('gravity-ball'),
                          width: cellSide * .62,
                          height: cellSide * .62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-.45, -.48),
                              colors: [
                                Color(0xFFD7F5FF),
                                Color(0xFF78BDE0),
                                Color(0xFF458DBB),
                              ],
                              stops: [0, .55, 1],
                            ),
                            border: Border.all(
                              color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x7778BDE0),
                                blurRadius: 9, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
          )),
          const SizedBox(height: 10),
          if (!reported && !_engine.isFailed)
            Column(mainAxisSize: MainAxisSize.min, children: [
              _DirectionButton(icon: Icons.keyboard_arrow_up_rounded, label: 'Tilt up', onTap: () => _tilt(GravityDirection.up)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _DirectionButton(icon: Icons.keyboard_arrow_left_rounded, label: 'Tilt left', onTap: () => _tilt(GravityDirection.left)),
                const SizedBox(width: 52),
                _DirectionButton(icon: Icons.keyboard_arrow_right_rounded, label: 'Tilt right', onTap: () => _tilt(GravityDirection.right)),
              ]),
              _DirectionButton(icon: Icons.keyboard_arrow_down_rounded, label: 'Tilt down', onTap: () => _tilt(GravityDirection.down)),
            ]),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 6 ? 3 : _engine.moves <= 9 ? 2 : 1,
                detail: 'Rolled the core to the exit.', onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'MOVES USED',
                detail: 'Each tilt rolls the core until a wall stops it.', onRetry: replayLevel))
          else
            HintLine(_feedback, palette: _palette),
        ]));
    }),
  );
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: 46, height: 44,
    child: ChunkyButton(key: ValueKey('gravity-tilt-${label.split(' ').last}'),
      onPressed: onTap, semanticLabel: label,
      color: Colors.white, edgeColor: _palette.edge,
      depth: 3, radius: 10, padding: EdgeInsets.zero,
      child: Icon(icon, color: _palette.ink, size: 27)));
}
