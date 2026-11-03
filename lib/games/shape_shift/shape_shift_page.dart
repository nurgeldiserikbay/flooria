import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'shape_shift_engine.dart';

const _palette = GamePalette(ground: Color(0xFFFFEEF0), surface: Colors.white, ink: Color(0xFF6D3E50),
  muted: Color(0xFFA27888), accent: Color(0xFFE66C8D), edge: Color(0xFF6D3E50));
Widget buildShapeShiftPage(BuildContext context, GameLaunch launch) => ShapeShiftPage(launch: launch);

class ShapeShiftPage extends StatefulWidget {
  const ShapeShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<ShapeShiftPage> createState() => _ShapeShiftPageState();
}

class _ShapeShiftPageState extends State<ShapeShiftPage> with LevelFlow<ShapeShiftPage> {
  late ShapeShiftEngine _engine;
  String _message = 'PICK THE FORM THAT FITS';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() { _engine = ShapeShiftEngine.forLevel(level); _message = 'PICK THE FORM THAT FITS'; }
  void _choose(ShiftShape shape) {
    final result = _engine.choose(shape);
    if (result == ShapeShiftResult.ignored) return;
    setState(() => _message = result == ShapeShiftResult.wrong ? 'WRONG GATE · TRY THE NEXT FORM' : 'NICE FIT!');
    if (result == ShapeShiftResult.wrong) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    if (result == ShapeShiftResult.completed) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Shape Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 16), child: Column(children: [
      SegmentBar(total: _engine.gates.length, done: _engine.index, palette: _palette),
      const Spacer(),
      Text('GATE ${math.min(_engine.index + 1, _engine.gates.length)} / ${_engine.gates.length}', style: TextStyle(color: _palette.muted,
        fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      const SizedBox(height: 15),
      AnimatedContainer(duration: const Duration(milliseconds: 220), width: 176, height: 176,
        decoration: BoxDecoration(color: const Color(0xFFFFD7E0), borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _palette.edge, width: 3), boxShadow: const [BoxShadow(color: Color(0xFFD89AAE), offset: Offset(0, 7))]),
        child: Center(child: _engine.isCompleted ? const Icon(Icons.celebration_rounded, size: 74, color: Color(0xFFE66C8D)) :
          _shapeIcon(_engine.current, 84, const Color(0xFFE66C8D)))),
      const SizedBox(height: 17),
      Text(_message, textAlign: TextAlign.center, style: TextStyle(color: _palette.ink, fontWeight: FontWeight.w900, letterSpacing: .9)),
      const Spacer(),
      Row(children: [for (final shape in ShiftShape.values) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(height: 92, child: ChunkyButton(onPressed: reported || _engine.isFailed ? null : () => _choose(shape),
          color: Colors.white, edgeColor: _palette.edge, radius: 17, child: _shapeIcon(shape, 42, _palette.accent)))))]),
      const SizedBox(height: 10),
      if (reported) LevelResultPanel(palette: _palette, launch: launch, level: level,
        stars: _engine.mistakes == 0 ? 3 : _engine.mistakes == 1 ? 2 : 1, detail: 'Every form fit its gate.', onReplay: replayLevel, onNext: nextLevel)
      else if (_engine.isFailed) RetryPanel(palette: _palette, title: 'TOO MANY WRONG FORMS',
        detail: 'Watch the opening, then choose the matching shape.', onRetry: replayLevel)
      else HintLine('MISTAKES ${_engine.mistakes} / ${_engine.allowedMistakes}', palette: _palette),
    ])),
  );
}

Widget _shapeIcon(ShiftShape shape, double size, Color color) => Icon(switch (shape) {
  ShiftShape.circle => Icons.circle_rounded, ShiftShape.square => Icons.square_rounded, ShiftShape.triangle => Icons.change_history_rounded,
}, size: size, color: color);
