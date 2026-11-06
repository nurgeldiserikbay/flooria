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
            key: const ValueKey('snake-board'),
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
                key: ValueKey('snake-food-${_engine.food}'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                    ? Duration.zero : const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                builder: (context, t, _) => CustomPaint(
                  painter: _SnakePainter(_engine, foodPop: t),
                ),
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
  const _SnakePainter(this.engine, {this.foodPop = 1});
  final SnakeEngine engine;
  final double foodPop;
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / engine.size;
    final board = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(18)),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8FFF7), Color(0xFFDCF1E0)],
      ).createShader(board),
    );
    // Restrained checker pattern makes movement easier to follow.
    for (var y = 0; y < engine.size; y++) {
      for (var x = 0; x < engine.size; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            Paint()..color = const Color(0x0C4D9975),
          );
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
      final foodCenter = Offset(
        (engine.food % engine.size + .5) * cell,
        (engine.food ~/ engine.size + .5) * cell,
      );
      final radius = cell * .27 * (.8 + .2 * foodPop);
      canvas.drawCircle(foodCenter, radius * 1.55,
        Paint()..color = const Color(0x55FF9770));
      canvas.drawCircle(foodCenter.translate(0, cell * .05), radius,
        Paint()..color = const Color(0xFFB8594F));
      canvas.drawCircle(foodCenter, radius,
        Paint()..color = const Color(0xFFFF8F63));
      canvas.drawCircle(
        foodCenter.translate(-cell * .075, -cell * .095),
        radius * .25,
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: foodCenter.translate(cell * .06, -radius * 1.02),
          width: radius * .8,
          height: radius * .4,
        ),
        Paint()..color = const Color(0xFF438F62),
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
        RRect.fromRectAndRadius(rect.shift(const Offset(0, 2)),
          Radius.circular(cell * .24)),
        Paint()..color = const Color(0x44265A43),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect,
        Radius.circular(cell * .24)), Paint()..color = color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + cell * .08,
            rect.top + cell * .055,
            rect.width * .55,
            cell * .09,
          ),
          Radius.circular(cell * .07),
        ),
        Paint()..color = Colors.white.withValues(alpha: .3),
      );
    }
    if (engine.body.isNotEmpty) {
      final head = engine.body.first;
      final center = Offset(
        (head % engine.size + .5) * cell,
        (head ~/ engine.size + .5) * cell,
      );
      final (forward, sideways) = switch (engine.direction) {
        SnakeDirection.up =>
            (const Offset(0, -1), const Offset(1, 0)),
        SnakeDirection.right =>
            (const Offset(1, 0), const Offset(0, 1)),
        SnakeDirection.down =>
            (const Offset(0, 1), const Offset(1, 0)),
        SnakeDirection.left =>
            (const Offset(-1, 0), const Offset(0, 1)),
      };
      for (final sign in const [-1.0, 1.0]) {
        final eye = center +
            forward * (cell * .10) + sideways * (sign * cell * .13);
        canvas.drawCircle(
          eye, cell * .075, Paint()..color = Colors.white);
        canvas.drawCircle(
          eye + forward * (cell * .025),
          cell * .035,
          Paint()..color = const Color(0xFF294E3A),
        );
      }
      final cheek = center - forward * (cell * .11);
      canvas.drawCircle(
        cheek,
        cell * .055,
        Paint()..color = const Color(0x77FFD9B7),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
