import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'clone_shift_engine.dart';

const _palette = GamePalette(ground: Color(0xFFEAF4FF), surface: Colors.white, ink: Color(0xFF3F5571),
  muted: Color(0xFF8195AE), accent: Color(0xFF5598D5), edge: Color(0xFF3F5571));
Widget buildCloneShiftPage(BuildContext context, GameLaunch launch) => CloneShiftPage(launch: launch);

class CloneShiftPage extends StatefulWidget {
  const CloneShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<CloneShiftPage> createState() => _CloneShiftPageState();
}

class _CloneShiftPageState extends State<CloneShiftPage> with LevelFlow<CloneShiftPage> {
  late CloneShiftEngine _engine;
  int _stationaryPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = CloneShiftEngine.forLevel(level);
    _stationaryPulse = 0;
  }

  void _move(CloneDirection direction) {
    final previous = List<int>.of(_engine.positions);
    final result = _engine.move(direction);
    if (result == CloneMove.ignored) return;
    setState(() {
      if (_engine.positions[0] == previous[0] &&
          _engine.positions[1] == previous[1]) {
        _stationaryPulse++;
      }
    });
    if (result == CloneMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Clone Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette,
      onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final movementDuration = reducedMotion
          ? Duration.zero : const Duration(milliseconds: 210);
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 370 : 310)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'MOVES', value: _engine.moves.toString(), palette: _palette),
          const Text('↔', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5598D5))),
          StatChip(label: 'LIMIT', value: _engine.limit.toString(), palette: _palette),
        ])),
        const SizedBox(height: 10),
        Container(
          width: side,
          height: side,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFDDEBF9),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFB5CBE2)),
            boxShadow: const [
              BoxShadow(color: Color(0x263F5571),
                blurRadius: 16, offset: Offset(0, 5)),
            ],
          ),
          child: LayoutBuilder(builder: (context, board) {
            final tileSize = (board.maxWidth -
                (CloneShiftEngine.side - 1) * 3) / CloneShiftEngine.side;
            return Stack(
              key: const ValueKey('clone-board'),
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: CloneShiftEngine.side * CloneShiftEngine.side,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: CloneShiftEngine.side,
                    crossAxisSpacing: 3, mainAxisSpacing: 3,
                  ),
                  itemBuilder: (context, cell) {
                    final wall = _engine.walls.contains(cell);
                    final goal = _engine.goals.contains(cell);
                    final explorer = _engine.positions.indexOf(cell);
                    return Semantics(
                      key: ValueKey('clone-cell-$cell'),
                      label: 'Row ${cell ~/ CloneShiftEngine.side + 1}, '
                          'column ${cell % CloneShiftEngine.side + 1}, '
                          '${wall ? 'wall' : goal ? 'star goal' : 'floor'}'
                          '${explorer >= 0 ? ', explorer ${explorer + 1}' : ''}',
                      child: AnimatedContainer(
                        duration: movementDuration,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: wall
                                ? const [
                                    Color(0xFFA1B2C9),
                                    Color(0xFF7D8EA8),
                                  ]
                                : goal
                                    ? const [
                                        Color(0xFFFFF5D8),
                                        Color(0xFFFFE6AA),
                                      ]
                                    : const [
                                        Colors.white,
                                        Color(0xFFF2F7FF),
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: wall ? const Color(0xFF6C7B93)
                                : goal ? const Color(0xFFEFCF8E)
                                : const Color(0xFFD5E1EF),
                          ),
                        ),
                        child: goal
                            ? const Icon(Icons.star_rounded,
                                color: Color(0xFFE1A83A), size: 24)
                            : wall
                                ? const Icon(Icons.square_rounded,
                                    size: 12, color: Color(0xFF60718A))
                                : null,
                      ),
                    );
                  },
                ),
                for (var explorer = 0;
                    explorer < _engine.positions.length; explorer++)
                  AnimatedPositioned(
                    key: ValueKey('clone-avatar-$explorer'),
                    duration: movementDuration,
                    curve: Curves.easeInOutCubic,
                    left: (_engine.positions[explorer] % CloneShiftEngine.side) *
                        (tileSize + 3),
                    top: (_engine.positions[explorer] ~/ CloneShiftEngine.side) *
                        (tileSize + 3),
                    width: tileSize,
                    height: tileSize,
                    child: IgnorePointer(
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: explorer == 0
                                ? const Color(0xFFFFE2D2)
                                : const Color(0xFFDDE8FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: explorer == 0
                                  ? const Color(0xFFDB775A)
                                  : const Color(0xFF6388CC),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Color(0x29415A78),
                                blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.face_rounded,
                              size: tileSize * .48,
                              color: explorer == 0
                                  ? const Color(0xFFD76E4D)
                                  : const Color(0xFF5C85D0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 9),
        _DirectionPad(onMove: _move, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(10), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 7 ? 3 : 2, detail: 'Both explorers found their stars.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(10), child: RetryPanel(palette: _palette,
          title: 'OUT OF MOVES', detail: 'Guide both linked explorers to their stars.', onRetry: replayLevel))
        else Shake(
          trigger: _stationaryPulse,
          child: const HintLine(
            'THE BLUE CLONE MOVES IN MIRROR',
            palette: _palette),
        ),
      ]));
    }));
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onMove, required this.disabled});
  final ValueChanged<CloneDirection> onMove; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3,
    children: [for (final d in [null, CloneDirection.up, null, CloneDirection.left, null, CloneDirection.right, null, CloneDirection.down, null])
      d == null ? const SizedBox() : ChunkyIconButton(icon: switch (d) { CloneDirection.up => Icons.keyboard_arrow_up_rounded,
        CloneDirection.right => Icons.keyboard_arrow_right_rounded, CloneDirection.down => Icons.keyboard_arrow_down_rounded,
        CloneDirection.left => Icons.keyboard_arrow_left_rounded }, tooltip: d.name, palette: _palette, onPressed: disabled ? null : () => onMove(d))]));
}
