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
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = CloneShiftEngine.forLevel(level);
  void _move(CloneDirection d) {
    _engine.move(d); setState(() {}); HapticFeedback.selectionClick();
    if (_engine.isCompleted) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Clone Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette,
      onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 370 : 310)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'MOVES', value: _engine.moves.toString(), palette: _palette),
          const Text('↔', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5598D5))),
          StatChip(label: 'LIMIT', value: _engine.limit.toString(), palette: _palette),
        ])),
        const SizedBox(height: 10),
        Container(width: side, height: side, padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: const Color(0xFFD5E5F5), borderRadius: BorderRadius.circular(20), border: Border.all(color: _palette.edge, width: 2)),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final avatar = _engine.positions.indexOf(cell);
              final goal = _engine.goals.contains(cell);
              return Container(decoration: BoxDecoration(color: _engine.walls.contains(cell) ? const Color(0xFF8292A9) : Colors.white,
                borderRadius: BorderRadius.circular(7)), child: Center(child: avatar >= 0
                  ? Icon(Icons.face_rounded, color: avatar == 0 ? const Color(0xFFED855D) : const Color(0xFF6688D5), size: side / 13)
                  : goal ? const Icon(Icons.star_rounded, color: Color(0xFFE9B849))
                  : _engine.walls.contains(cell) ? const Icon(Icons.square_rounded, size: 12, color: Color(0xFF60718A)) : null));
            })),
        const SizedBox(height: 9),
        _DirectionPad(onMove: _move, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(10), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 7 ? 3 : 2, detail: 'Both explorers found their stars.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(10), child: RetryPanel(palette: _palette,
          title: 'OUT OF MOVES', detail: 'Guide both linked explorers to their stars.', onRetry: replayLevel))
        else const HintLine('THE BLUE CLONE MOVES IN MIRROR', palette: _palette),
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
