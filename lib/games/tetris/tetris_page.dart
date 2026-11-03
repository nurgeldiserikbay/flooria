import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'tetris_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE8F1FA), surface: Colors.white, ink: Color(0xFF263E5D),
  muted: Color(0xFF758AA3), accent: Color(0xFF4F8FCB), edge: Color(0xFF263E5D),
);
const _blockColors = [
  Color(0xFF62BDE8), Color(0xFFF1C15A), Color(0xFF9D78D6),
  Color(0xFF5886D8), Color(0xFFED9859), Color(0xFF6CBF9D),
  Color(0xFFE66F78),
];

Widget buildTetrisPage(BuildContext context, GameLaunch launch) =>
    TetrisPage(launch: launch);

class TetrisPage extends StatefulWidget {
  const TetrisPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<TetrisPage> createState() => _TetrisPageState();
}

class _TetrisPageState extends State<TetrisPage> with LevelFlow<TetrisPage> {
  late TetrisEngine _engine;
  Timer? _gravity;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _gravity?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _gravity?.cancel();
    _engine = TetrisEngine.forLevel(level);
    _gravity = Timer.periodic(Duration(milliseconds: _engine.gravityMilliseconds), (_) {
      if (!mounted) return;
      _apply(_engine.tick());
    });
  }

  void _action(TetrisAction action) => _apply(_engine.act(action));
  void _apply(TetrisTick result) {
    if (result == TetrisTick.ignored) return;
    setState(() {});
    if (result == TetrisTick.completed) {
      _gravity?.cancel();
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == TetrisTick.failed) {
      _gravity?.cancel();
      HapticFeedback.vibrate();
    } else if (result == TetrisTick.lineClear) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Tetris',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final reserve = reported || _engine.isFailed ? 260.0 : 170.0;
      final boardHeight = min(constraints.maxWidth * 1.18,
          constraints.maxHeight - reserve).clamp(280.0, 460.0).toDouble();
      final boardWidth = boardHeight * TetrisEngine.width / TetrisEngine.height;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'LINES', value: '${_engine.clearedLines}/${_engine.goalLines}', palette: _palette),
                StatChip(label: 'SCORE', value: '${_engine.score}', palette: _palette),
              ])),
          const SizedBox(height: 8),
          SizedBox(width: boardWidth, height: boardHeight,
            child: CustomPaint(painter: _TetrisPainter(_engine))),
          const SizedBox(height: 8),
          if (!reported && !_engine.isFailed) _Controls(onAction: _action),
          if (reported) ...[
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.score >= _engine.goalLines * 180 ? 3 : 2,
                detail: 'You cleared ${_engine.clearedLines} lines.',
                onReplay: replayLevel, onNext: nextLevel)),
          ] else if (_engine.isFailed) ...[
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'STACK TOPPED OUT',
                detail: 'Clear the line goal before the board fills.',
                onRetry: replayLevel)),
          ] else
            const HintLine('CLEAR LINES TO REACH THE GOAL', palette: _palette,
              height: 28),
        ]));
    }),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({required this.onAction});
  final ValueChanged<TetrisAction> onAction;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      _Control(icon: Icons.arrow_left_rounded, label: 'Left',
        action: TetrisAction.left, onAction: onAction),
      _Control(icon: Icons.arrow_downward_rounded, label: 'Drop one',
        action: TetrisAction.down, onAction: onAction),
      _Control(icon: Icons.arrow_right_rounded, label: 'Right',
        action: TetrisAction.right, onAction: onAction),
      _Control(icon: Icons.rotate_right_rounded, label: 'Rotate',
        action: TetrisAction.rotate, onAction: onAction),
      _Control(icon: Icons.vertical_align_bottom_rounded, label: 'Hard drop',
        action: TetrisAction.hardDrop, onAction: onAction),
    ]);
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.label,
    required this.action, required this.onAction});
  final IconData icon;
  final String label;
  final TetrisAction action;
  final ValueChanged<TetrisAction> onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: SizedBox(width: 48, height: 50,
      child: ChunkyIconButton(icon: icon, tooltip: label, size: 46,
        palette: _palette, onPressed: () => onAction(action))),
  );
}

class _TetrisPainter extends CustomPainter {
  const _TetrisPainter(this.engine);
  final TetrisEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / TetrisEngine.width;
    final cellH = size.height / TetrisEngine.height;
    final bounds = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(14)),
      Paint()..color = const Color(0xFFCAD8E7));
    final settled = engine.board;
    final active = engine.activeCells().toSet();
    for (var index = 0; index < settled.length; index++) {
      final value = active.contains(index) ? engine.activeColor : settled[index];
      final row = index ~/ TetrisEngine.width, col = index % TetrisEngine.width;
      final rect = Rect.fromLTWH(col*cellW+1.5, row*cellH+1.5,
          cellW-3, cellH-3);
      final color = value == 0 ? const Color(0xFFF7FAFE)
          : _blockColors[(value - 1) % _blockColors.length];
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color);
      if (value != 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: .18));
      }
    }
    final border = Paint()..color = _palette.edge.withValues(alpha: .65)
      ..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(14)), border);
  }
  @override
  bool shouldRepaint(covariant _TetrisPainter old) => true;
}
