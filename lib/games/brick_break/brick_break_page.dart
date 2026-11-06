import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'brick_break_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF0DD), surface: Colors.white, ink: Color(0xFF503A35),
  muted: Color(0xFF987D70), accent: Color(0xFFEF7654), edge: Color(0xFF503A35),
);

Widget buildBrickBreakPage(BuildContext context, GameLaunch launch) =>
    BrickBreakPage(launch: launch);

class BrickBreakPage extends StatefulWidget {
  const BrickBreakPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<BrickBreakPage> createState() => _BrickBreakPageState();
}

class _BrickBreakPageState extends State<BrickBreakPage> with LevelFlow<BrickBreakPage> {
  late BrickBreakEngine _engine;
  Timer? _timer;
  DateTime? _lastTick;
  final List<Offset> _ballTrail = [];
  double _impactFlash = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _timer?.cancel();
    _engine = BrickBreakEngine.forLevel(level);
    _lastTick = null;
    _ballTrail.clear();
    _impactFlash = 0;
  }

  void _start() {
    if (_engine.launched || reported) return;
    _engine.launchBall();
    HapticFeedback.lightImpact();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final dt = _lastTick == null ? .016 : now.difference(_lastTick!).inMicroseconds / 1000000;
      _lastTick = now;
      final before = _engine.remaining;
      if (_engine.launched) {
        _ballTrail.add(Offset(_engine.ballX, _engine.ballY));
        if (_ballTrail.length > 7) _ballTrail.removeAt(0);
      }
      final state = _engine.tick(dt);
      if (_engine.remaining < before) {
        _impactFlash = 1;
      } else {
        _impactFlash = (_impactFlash - .095).clamp(0.0, 1.0).toDouble();
      }
      if (state == BrickTick.lifeLost) _ballTrail.clear();
      setState(() {});
      if (state == BrickTick.lifeLost) HapticFeedback.selectionClick();
      if (state == BrickTick.cleared) {
        _timer?.cancel();
        HapticFeedback.mediumImpact();
        reportWin(score: _engine.score, metrics: {'control': _engine.controlMetric});
      } else if (state == BrickTick.gameOver) {
        _timer?.cancel();
      }
    });
  }

  void _movePaddle(Offset local, double width) {
    _engine.setPaddle(local.dx / width);
    if (!_engine.launched) _engine.ballX = _engine.paddleX;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Brick Break', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final width = (box.maxWidth - 32).clamp(260.0, 430.0).toDouble();
      final reserve = reported || _engine.isFailed ? 270.0 : 145.0;
      final availableHeight = (box.maxHeight - reserve).clamp(240.0, 460.0).toDouble();
      final height = (width / .72).clamp(240.0, availableHeight).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            StatChip(label: 'LEFT', value: '${_engine.remaining}', palette: _palette),
            StatChip(label: 'SCORE', value: '${_engine.score}', palette: _palette),
            StatChip(label: 'LIVES', value: '${_engine.lives}', palette: _palette),
          ])),
        SizedBox(width: width, height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _start,
            onPanStart: (d) { _movePaddle(d.localPosition, width); _start(); },
            onPanUpdate: (d) => _movePaddle(d.localPosition, width),
            child: CustomPaint(
              painter: _BrickPainter(
                _engine,
                trail: _ballTrail,
                hitFlash: _impactFlash,
              ),
            ),
          )),
        const SizedBox(height: 8),
        Text(_engine.isCompleted ? 'BOARD CLEARED' : _engine.isFailed ? 'TRY AGAIN' : 'MOVE THE PADDLE  ·  TAP TO LAUNCH',
          style: TextStyle(color: _palette.muted, fontSize: 10,
            fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        if (_engine.isCompleted)
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: LevelResultPanel(palette: _palette, launch: launch, level: level,
              stars: _engine.lives == 3 ? 3 : _engine.lives == 2 ? 2 : 1,
              detail: 'Every block is gone.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed)
          Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: RetryPanel(palette: _palette, title: 'BALLS USED',
              detail: 'Reset the board and try again.', onRetry: replayLevel)),
      ]));
    }),
  );
}

class _BrickPainter extends CustomPainter {
  const _BrickPainter(this.engine, {
    required this.trail,
    required this.hitFlash,
  });
  final BrickBreakEngine engine;
  final List<Offset> trail;
  final double hitFlash;
  static const colors = [Color(0xFFFF9D65), Color(0xFFFFC857), Color(0xFF7BCDB3), Color(0xFF77B8E8), Color(0xFFAE92E8), Color(0xFFEC83A7)];
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bounds.shift(const Offset(0, 4)),
        const Radius.circular(22),
      ),
      Paint()..color = const Color(0xFFD9AF93),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(22)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFEBD7)],
        ).createShader(bounds),
    );
    for (var x = 0; x < 7; x++) {
      final c = Offset(size.width * (x + 1) / 8, size.height * .77);
      canvas.drawCircle(c, 1.8, Paint()..color = const Color(0x33EF7654));
    }
    final bw = size.width * .92 / engine.columns;
    final bh = size.height * (engine.rows > 4 ? .044 : .052);
    for (final id in engine.alive) {
      final row = id ~/ engine.columns, col = id % engine.columns;
      final rect = Rect.fromLTWH(size.width*.04 + col*bw, size.height*.12 + row*(bh+size.height*.014), bw-4, bh);
      final color = colors[row % colors.length];
      canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 3)), const Radius.circular(6)), Paint()..color = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness-.2).clamp(0.0,1.0)).toColor());
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = color);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(4)), Paint()..color = Colors.white.withValues(alpha: .18));
    }
    final paddle = Rect.fromCenter(center: Offset(engine.paddleX*size.width, size.height*.92), width: size.width*.25, height: size.height*.035);
    canvas.drawRRect(RRect.fromRectAndRadius(paddle.shift(const Offset(0, 3)), const Radius.circular(12)), Paint()..color = const Color(0xFFB65342));
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB381), Color(0xFFEC6C50)],
        ).createShader(paddle),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle.deflate(3), const Radius.circular(9)),
      Paint()..color = Colors.white.withValues(alpha: .22),
    );
    for (var i = 0; i < trail.length; i++) {
      final past = trail[i];
      canvas.drawCircle(
        Offset(past.dx * size.width, past.dy * size.height),
        size.width * (.006 + .010 * (i + 1) / trail.length),
        Paint()..color = const Color(0xFFEF7654).withValues(
          alpha: .10 + .22 * (i + 1) / trail.length,
        ),
      );
    }
    final ball = Offset(engine.ballX * size.width, engine.ballY * size.height);
    final glowRadius = size.width * (.065 + hitFlash * .045);
    canvas.drawCircle(
      ball,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x88FFC857).withValues(alpha: .22 + hitFlash * .38),
            const Color(0x00FFC857),
          ],
        ).createShader(Rect.fromCircle(center: ball, radius: glowRadius)),
    );
    canvas.drawCircle(
      ball.translate(0, size.width * .003),
      size.width * .019,
      Paint()..color = const Color(0xFF8B564A),
    );
    canvas.drawCircle(
      ball,
      size.width * .018,
      Paint()..color = const Color(0xFFFFF8E7),
    );
    canvas.drawCircle(
      ball.translate(-size.width * .005, -size.width * .005),
      size.width * .006,
      Paint()..color = Colors.white,
    );
  }
  @override
  bool shouldRepaint(covariant _BrickPainter old) => true;
}
