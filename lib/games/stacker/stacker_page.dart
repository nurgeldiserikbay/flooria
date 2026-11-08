import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'stacker_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF2FB), surface: Colors.white, ink: Color(0xFF344B68),
  muted: Color(0xFF7E91AA), accent: Color(0xFF568DCA), edge: Color(0xFF344B68),
);
const _layerColors = [
  Color(0xFF67B5DC), Color(0xFF82C39B), Color(0xFFF1C65B),
  Color(0xFFE99A6D), Color(0xFFBD83D1), Color(0xFFEA7B91), Color(0xFF5BAEAC),
];

Widget buildStackerPage(BuildContext context, GameLaunch launch) =>
    StackerPage(launch: launch);

class StackerPage extends StatefulWidget {
  const StackerPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<StackerPage> createState() => _StackerPageState();
}

class _StackerPageState extends State<StackerPage> with LevelFlow<StackerPage> {
  late StackerEngine _engine;
  Timer? _timer;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _timer?.cancel();
    _engine = StackerEngine.forLevel(level);
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted || !_engine.tick()) return;
      setState(() {});
    });
  }

  void _drop() {
    if (reported) return;
    final result = _engine.drop();
    setState(() {});
    if (result == StackDrop.completed) {
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == StackDrop.failed) {
      _timer?.cancel();
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Stacker',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final boardWidth = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 250 : 170))
        .clamp(250.0, 390.0).toDouble();
      final boardHeight = min(boardWidth * 1.08, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'STACK', value: '${_engine.placed}/${_engine.targetLayers}', palette: _palette),
                StatChip(label: 'WIDTH', value: '${(_engine.layers.last.width * 100).round()}%', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Semantics(
            key: const ValueKey('stacker-board-state'),
            button: true,
            enabled: !reported && !_engine.isFailed,
            label: 'Drop block. ${_engine.placed} of ${_engine.targetLayers} layers. '
              'Stack width ${(_engine.layers.last.width * 100).round()} percent',
            child: GestureDetector(onTap: reported || _engine.isFailed ? null : _drop,
            child: Container(
              key: const ValueKey('stacker-board'),
              width: boardWidth, height: boardHeight,
              decoration: BoxDecoration(color: const Color(0xFFDCE9F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _palette.edge, width: 2),
                boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
              child: CustomPaint(painter: _StackPainter(_engine)),
            ))),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.layers.last.width >= .65 ? 3
                  : _engine.layers.last.width >= .4 ? 2 : 1,
                detail: 'Built a stable stack to the target height.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'BLOCK MISSED',
                detail: 'Tap when the moving block lines up.', onRetry: replayLevel))
          else
            const HintLine('TAP TO DROP THE MOVING BLOCK', palette: _palette),
        ]));
    }),
  );
}

class _StackPainter extends CustomPainter {
  const _StackPainter(this.engine);
  final StackerEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    const blockHeight = 17.0;
    final baseline = size.height - 13;
    // A quiet measuring guide lets players read the target alignment without
    // depending on the block colours alone.
    final target = engine.layers.last;
    final guide = Rect.fromLTWH(target.left * size.width,
      8, target.width * size.width, baseline - 8);
    canvas.drawRRect(RRect.fromRectAndRadius(guide, const Radius.circular(7)),
      Paint()..color = const Color(0xFF78BCE5).withValues(alpha: .12));
    final guidePaint = Paint()
      ..color = const Color(0xFF568DCA).withValues(alpha: .45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(guide.left, 8), Offset(guide.left, baseline), guidePaint);
    canvas.drawLine(Offset(guide.right, 8), Offset(guide.right, baseline), guidePaint);
    for (var i = 0; i < engine.layers.length; i++) {
      final layer = engine.layers[i];
      final top = baseline - blockHeight * (i + 1);
      final rect = Rect.fromLTWH(layer.left * size.width, top,
        layer.width * size.width, blockHeight - 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 2)),
        const Radius.circular(4)),
        Paint()..color = const Color(0xFF466582).withValues(alpha: .28));
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = _layerColors[layer.colorIndex]);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: .24));
    }
    if (!engine.isCompleted && !engine.isFailed) {
      final rect = Rect.fromLTWH(engine.movingLeft * size.width,
        baseline - blockHeight * (engine.layers.length + 1),
        engine.layers.last.width * size.width, blockHeight - 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(5)),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: .5));
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = _layerColors[engine.layers.length % _layerColors.length]);
    }
  }
  @override
  bool shouldRepaint(covariant _StackPainter oldDelegate) => true;
}
