import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'snake_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF5EE), surface: Colors.white, ink: Color(0xFF294E3A),
  muted: Color(0xFF789381), accent: Color(0xFF4DA875), edge: Color(0xFF294E3A),
);

Widget buildSnakePage(BuildContext context, GameLaunch launch) =>
    SnakePage(launch: launch);

class SnakePage extends StatefulWidget {
  const SnakePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage> with LevelFlow<SnakePage> {
  late SnakeEngine _engine;
  Timer? _timer;
  bool _started = false;
  Offset _drag = Offset.zero;

  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _timer?.cancel();
    _engine = SnakeEngine.forLevel(level);
    _started = false;
    _drag = Offset.zero;
  }

  void _start() {
    if (_started || reported || _engine.isFailed) return;
    setState(() => _started = true);
    _timer = Timer.periodic(Duration(milliseconds: _engine.stepMilliseconds), (_) {
      if (!mounted) return;
      final result = _engine.step();
      setState(() {});
      if (result == SnakeStep.ateFood) HapticFeedback.selectionClick();
      if (result == SnakeStep.completed) {
        _timer?.cancel();
        HapticFeedback.mediumImpact();
        reportWin(score: _engine.score, metrics: const {});
      } else if (result == SnakeStep.crashed) {
        _timer?.cancel();
        HapticFeedback.vibrate();
      }
    });
  }

  void _turn(SnakeDirection direction) {
    if (_engine.turn(direction)) HapticFeedback.selectionClick();
  }

  void _finishSwipe(Offset delta) {
    if (delta.distance < 18) return;
    _turn(delta.dx.abs() > delta.dy.abs()
        ? delta.dx > 0 ? SnakeDirection.right : SnakeDirection.left
        : delta.dy > 0 ? SnakeDirection.down : SnakeDirection.up);
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Snake',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final reserve = reported || _engine.isFailed ? 265.0 : 215.0;
      final boardSide = min(constraints.maxWidth - 32,
          constraints.maxHeight - reserve).clamp(190.0, 400.0).toDouble();
      final showControls = !reported && !_engine.isFailed;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'LENGTH', value: '${_engine.length}/${_engine.goalLength}', palette: _palette),
                StatChip(label: 'SCORE', value: '${_engine.score}', palette: _palette),
              ])),
          const SizedBox(height: 10),
          GestureDetector(
            onPanStart: (_) => _drag = Offset.zero,
            onPanUpdate: (details) {
              _drag += details.delta;
              if (_drag.distance >= 24) {
                _finishSwipe(_drag);
                _drag = Offset.zero;
              }
            },
            onPanEnd: (_) => _drag = Offset.zero,
            onTap: _started ? null : _start,
            child: SizedBox(
              width: boardSide,
              height: boardSide,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('snake-food-${_engine.length}'),
                tween: Tween(begin: .965, end: 1),
                duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: CustomPaint(painter: _SnakePainter(_engine)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (showControls) ...[
            if (!_started)
              SizedBox(height: 42, child: ChunkyButton(
                onPressed: _start, color: _palette.accent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: const Text('START', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, letterSpacing: 1.2))))
            else
              _DirectionPad(onDirection: _turn, palette: _palette),
            const SizedBox(height: 2),
            HintLine(_started ? 'SWIPE OR USE THE ARROWS' : 'REACH THE LENGTH GOAL',
              palette: _palette, height: 28),
          ],
          if (reported) ...[
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.length >= _engine.goalLength + 2 ? 3 : 2,
                detail: 'You reached length ${_engine.length}.',
                onReplay: replayLevel, onNext: nextLevel)),
          ] else if (_engine.isFailed) ...[
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'SNAKE STOPPED',
                detail: 'Try again and reach ${_engine.goalLength}.',
                onRetry: replayLevel)),
          ],
        ]));
    }),
  );
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onDirection, required this.palette});
  final ValueChanged<SnakeDirection> onDirection;
  final GamePalette palette;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min,
    children: [
      _ArrowButton(icon: Icons.keyboard_arrow_up_rounded,
        direction: SnakeDirection.up, onDirection: onDirection, palette: palette),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _ArrowButton(icon: Icons.keyboard_arrow_left_rounded,
          direction: SnakeDirection.left, onDirection: onDirection, palette: palette),
        const SizedBox(width: 8),
        _ArrowButton(icon: Icons.keyboard_arrow_down_rounded,
          direction: SnakeDirection.down, onDirection: onDirection, palette: palette),
        const SizedBox(width: 8),
        _ArrowButton(icon: Icons.keyboard_arrow_right_rounded,
          direction: SnakeDirection.right, onDirection: onDirection, palette: palette),
      ]),
    ]);
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.direction,
    required this.onDirection, required this.palette});
  final IconData icon;
  final SnakeDirection direction;
  final ValueChanged<SnakeDirection> onDirection;
  final GamePalette palette;
  @override
  Widget build(BuildContext context) => SizedBox(width: 46, height: 42,
    child: ChunkyButton(onPressed: () => onDirection(direction), color: Colors.white,
      edgeColor: palette.edge, depth: 3, radius: 12, padding: EdgeInsets.zero,
      child: Icon(icon, color: palette.accent, size: 28)));
}

class _SnakePainter extends CustomPainter {
  const _SnakePainter(this.engine);
  final SnakeEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / engine.size;
    final board = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(board.shift(const Offset(0, 3)),
          const Radius.circular(19)),
      Paint()..color = const Color(0xFFAACDB4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FFF7), Color(0xFFDCF1E0)],
        ).createShader(board),
    );
    // Quiet checkerboard areas give the snake more readable movement depth.
    for (var y = 0; y < engine.size; y++) {
      for (var x = 0; x < engine.size; x++) {
        if ((x + y).isEven) {
          final square = Rect.fromLTWH(x * cell, y * cell, cell, cell);
          canvas.drawRect(square,
              Paint()..color = const Color(0x0C4D9975));
        }
      }
    }
    final gridPaint = Paint()..color = const Color(0x1F5B8766)..strokeWidth = 1;
    for (var i = 1; i < engine.size; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
    }
    if (engine.food >= 0) {
      final foodCenter = Offset((engine.food % engine.size + .5) * cell,
          (engine.food ~/ engine.size + .5) * cell);
      canvas.drawCircle(foodCenter, cell * .38,
          Paint()..color = const Color(0x33FF8F63));
      canvas.drawCircle(foodCenter.translate(0, cell * .035), cell * .29,
          Paint()..color = const Color(0xFFD85B48));
      canvas.drawCircle(foodCenter, cell * .28,
          Paint()..color = const Color(0xFFFF9770));
      canvas.drawOval(
        Rect.fromCenter(
          center: foodCenter.translate(-cell * .09, -cell * .10),
          width: cell * .13,
          height: cell * .08,
        ),
        Paint()..color = Colors.white.withValues(alpha: .83),
      );
      canvas.drawLine(
        foodCenter.translate(0, -cell * .22),
        foodCenter.translate(cell * .045, -cell * .36),
        Paint()
          ..color = const Color(0xFF477C54)
          ..strokeWidth = cell * .065
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = engine.body.length - 1; i >= 0; i--) {
      final position = engine.body[i];
      final inset = i == 0 ? cell * .09 : cell * .13;
      final rect = Rect.fromLTWH((position % engine.size) * cell + inset,
          (position ~/ engine.size) * cell + inset,
          cell - inset * 2, cell - inset * 2);
      final color = i == 0 ? const Color(0xFF287B52)
          : Color.lerp(const Color(0xFF4DA875), const Color(0xFFA7D9AE),
              i / engine.body.length)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(Offset(0, cell * .055)),
          Radius.circular(cell * .24),
        ),
        Paint()..color = GamePalette.shade(color, .16),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .24)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .2)!, color],
          ).createShader(rect),
      );
      if (i > 0) {
        canvas.drawCircle(
          rect.topLeft + Offset(rect.width * .25, rect.height * .21),
          cell * .045,
          Paint()..color = Colors.white.withValues(alpha: .35),
        );
      }
    }
    if (engine.body.isNotEmpty) {
      final head = engine.body.first;
      final center = Offset((head % engine.size + .5) * cell,
          (head ~/ engine.size + .5) * cell);
      final eyePaint = Paint()..color = Colors.white;
      final offset = switch (engine.direction) {
        SnakeDirection.up => Offset(0, -cell*.12),
        SnakeDirection.right => Offset(cell*.12, 0),
        SnakeDirection.down => Offset(0, cell*.12),
        SnakeDirection.left => Offset(-cell*.12, 0),
      };
      final sideways = switch (engine.direction) {
        SnakeDirection.up || SnakeDirection.down => Offset(cell * .12, 0),
        SnakeDirection.left || SnakeDirection.right => Offset(0, cell * .12),
      };
      for (final eye in [center + offset - sideways, center + offset + sideways]) {
        canvas.drawCircle(eye, cell * .072, eyePaint);
        canvas.drawCircle(
          eye + Offset(cell * .02, cell * .015),
          cell * .033,
          Paint()..color = const Color(0xFF294E3A),
        );
      }
    }
  }
  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
