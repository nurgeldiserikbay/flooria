import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'tide_shift_engine.dart';

const _palette = GamePalette(ground: Color(0xFFE8F8F6), surface: Colors.white, ink: Color(0xFF315E5D),
  muted: Color(0xFF769E9C), accent: Color(0xFF36A99C), edge: Color(0xFF315E5D));
Widget buildTideShiftPage(BuildContext context, GameLaunch launch) => TideShiftPage(launch: launch);

class TideShiftPage extends StatefulWidget {
  const TideShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<TideShiftPage> createState() => _TideShiftPageState();
}

class _TideShiftPageState extends State<TideShiftPage> with LevelFlow<TideShiftPage> {
  late TideShiftEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = TideShiftEngine.forLevel(level);
  void _step(int dr, int dc) {
    final result = _engine.step(dr, dc); setState(() {});
    if (result == TideMove.flooded) HapticFeedback.heavyImpact(); else HapticFeedback.selectionClick();
    if (result == TideMove.completed) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Tide Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 350 : 300)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'TIDE', value: _engine.tide.toString(), palette: _palette),
          Row(children: [for (var i = 0; i < 4; i++) Icon(Icons.water_drop_rounded, size: 17,
            color: i < _engine.tide ? _palette.accent : const Color(0xFFC9E6E1))]),
          StatChip(label: 'STEPS', value: _engine.moves.toString(), palette: _palette),
        ])),
        const SizedBox(height: 9),
        Container(width: side, height: side, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFBFE4DD),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: _palette.edge, width: 2)),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 36,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final height = _engine.heights[cell];
              final flooded = height < _engine.tide;
              return AnimatedContainer(duration: const Duration(milliseconds: 220), decoration: BoxDecoration(
                color: flooded ? const Color(0xFF54B9C0) : height >= 4 ? const Color(0xFF9ACB8C) : const Color(0xFFD6C58B),
                borderRadius: BorderRadius.circular(7)), child: Center(child: cell == _engine.position
                  ? const Icon(Icons.directions_run_rounded, color: Color(0xFF315E5D), size: 22)
                  : cell == _engine.goal ? const Icon(Icons.flag_rounded, color: Colors.white, size: 20)
                  : flooded ? const Icon(Icons.water_rounded, color: Color(0xFFB9F3E8), size: 16) : null));
            })),
        const SizedBox(height: 9),
        _TidePad(onStep: _step, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 11 ? 3 : 2, detail: 'Reached high ground before the tide.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(8), child: RetryPanel(palette: _palette,
          title: 'THE TIDE CAUGHT YOU', detail: 'Stay on the raised green path.', onRetry: replayLevel))
        else const HintLine('LOW GROUND FLOODS AS THE TIDE RISES', palette: _palette),
      ]));
    }));
}

class _TidePad extends StatelessWidget {
  const _TidePad({required this.onStep, required this.disabled});
  final void Function(int, int) onStep; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, children: [
      const SizedBox(), _move(Icons.keyboard_arrow_up_rounded, -1, 0), const SizedBox(),
      _move(Icons.keyboard_arrow_left_rounded, 0, -1), const SizedBox(), _move(Icons.keyboard_arrow_right_rounded, 0, 1),
      const SizedBox(), _move(Icons.keyboard_arrow_down_rounded, 1, 0), const SizedBox(),
    ]));
  Widget _move(IconData icon, int dr, int dc) => ChunkyIconButton(icon: icon, tooltip: 'Move', palette: _palette,
    onPressed: disabled ? null : () => onStep(dr, dc));
}
