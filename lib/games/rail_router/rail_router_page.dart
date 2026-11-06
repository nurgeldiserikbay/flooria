import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'rail_router_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF4F0), surface: Colors.white, ink: Color(0xFF3F5B55),
  muted: Color(0xFF7E9990), accent: Color(0xFF5AAE92), edge: Color(0xFF3F5B55),
);
const _trainColors = [Color(0xFF579DD0), Color(0xFFE58A62)];

Widget buildRailRouterPage(BuildContext context, GameLaunch launch) =>
    RailRouterPage(launch: launch);

class RailRouterPage extends StatefulWidget {
  const RailRouterPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<RailRouterPage> createState() => _RailRouterPageState();
}

class _RailRouterPageState extends State<RailRouterPage> with LevelFlow<RailRouterPage> {
  late RailRouterEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = RailRouterEngine.forLevel(level);

  void _switch(int train) {
    if (_engine.toggle(train) == RailAction.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  void _advance() {
    final result = _engine.advance();
    setState(() {});
    if (result == RailAction.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == RailAction.collision) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Rail Router', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      // Leave room for both switches and the advance button on short phones.
      final size = min(constraints.maxWidth - 36,
        constraints.maxHeight - (reported || _engine.isFailed ? 300 : 280))
        .clamp(180.0, 360.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'TICK', value: '${_engine.time}', palette: _palette),
              StatChip(label: 'TRAINS', value: '${_engine.passed.where((x) => x).length}/2', palette: _palette),
            ])),
          const SizedBox(height: 9),
          Container(
            key: const ValueKey('rail-board'),
            width: size, height: size, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FAF4), Color(0xFFD0E7DF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _engine.time.toDouble()),
              duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                  ? Duration.zero : const Duration(milliseconds: 340),
              curve: Curves.easeInOutCubic,
              builder: (context, visualTime, _) => CustomPaint(
                painter: _RailPainter(_engine, visualTime: visualTime),
              ),
            ),
          ),
          const SizedBox(height: 9),
          if (!reported && !_engine.isFailed)
            for (var train = 0; train < 2; train++)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
              child: ChunkyButton(
                onPressed: reported || _engine.isFailed ? null : () => _switch(train),
                color: _engine.diverted[train] ? _trainColors[train] : Colors.white,
                edgeColor: _engine.diverted[train] ? GamePalette.shade(_trainColors[train]) : _palette.edge,
                depth: 3, radius: 12, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(children: [
                  Icon(Icons.train_rounded, color: _engine.diverted[train] ? Colors.white : _trainColors[train]),
                  const SizedBox(width: 8),
                  Expanded(child: Text('TRAIN ${train + 1} · ${_engine.diverted[train] ? 'BYPASS' : 'CROSSING'}',
                    style: TextStyle(color: _engine.diverted[train] ? Colors.white : _palette.ink,
                      fontWeight: FontWeight.w900))),
                  Text('${_engine.countdowns[train]} TICKS',
                    style: TextStyle(color: _engine.diverted[train] ? Colors.white : _palette.muted,
                      fontSize: 11, fontWeight: FontWeight.w900)),
                ]),
              )),
          const SizedBox(height: 3),
          if (!reported && !_engine.isFailed)
            SizedBox(width: 220, height: 48,
              child: ChunkyButton(onPressed: _advance, color: _palette.accent,
                edgeColor: _palette.edge, depth: 4, radius: 14,
                child: const Text('ADVANCE TRAINS', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)))),
          const SizedBox(height: 4),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.diverted.where((x) => x).length == 1 ? 3 : 2,
                detail: 'Both trains passed without a collision.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'COLLISION',
                detail: 'Switch one train onto the bypass.', onRetry: replayLevel))
          else
            const HintLine('SWITCH ONE ROUTE BEFORE THE TRAINS MEET', palette: _palette),
        ]));
    }),
  );
}

class _RailPainter extends CustomPainter {
  const _RailPainter(this.engine, {required this.visualTime});
  final RailRouterEngine engine;
  final double visualTime;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rail = Paint()
      ..color = const Color(0xFF627F75)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final stripe = Paint()
      ..color = const Color(0xFFDDECE4)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final sleeper = Paint()
      ..color = const Color(0xAA849A89)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Sleepers make the crossing read as railway tracks rather than lines.
    for (var i = 1; i < 12; i++) {
      final p = i * size.width / 12;
      canvas.drawLine(Offset(p, center.dy - 9),
          Offset(p, center.dy + 9), sleeper);
      canvas.drawLine(Offset(center.dx - 9, p),
          Offset(center.dx + 9, p), sleeper);
    }
    canvas.drawLine(Offset(0, center.dy),
        Offset(size.width, center.dy), rail);
    canvas.drawLine(Offset(center.dx, 0),
        Offset(center.dx, size.height), rail);
    canvas.drawLine(Offset(0, center.dy),
        Offset(size.width, center.dy), stripe);
    canvas.drawLine(Offset(center.dx, 0),
        Offset(center.dx, size.height), stripe);

    final bypass = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(center.dx + size.width * .28,
        center.dy - size.height * .36,
        center.dx + size.width * .28,
        center.dy + size.height * .36,
        center.dx, center.dy);
    canvas.drawPath(bypass, Paint()
      ..color = const Color(0xFF4AA888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(bypass, Paint()
      ..color = const Color(0xFFC6F0DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    final danger = engine.isFailed;
    canvas.drawCircle(center, 19,
        Paint()..color = danger
            ? const Color(0xFFF5A2A3) : const Color(0xFFFFE6A6));
    canvas.drawCircle(center, 10,
        Paint()..color = danger
            ? const Color(0xFFE55E64) : const Color(0xFFFFC86E));

    for (var train = 0; train < 2; train++) {
      if (engine.passed[train]) continue;
      final progress = (visualTime / engine.arrivals[train])
          .clamp(0.0, 1.0).toDouble();
      Offset point;
      if (!engine.diverted[train]) {
        point = train == 0
            ? Offset(size.width * progress, center.dy)
            : Offset(center.dx, size.height * progress);
      } else if (train == 0) {
        point = Offset(size.width * progress,
          center.dy - sin(progress * pi) * size.height * .28);
      } else {
        point = Offset(center.dx + sin(progress * pi) * size.width * .28,
          size.height * progress);
      }
      canvas.save();
      canvas.translate(point.dx, point.dy);
      if (train == 1) canvas.rotate(pi / 2);
      final wagon = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -10, 32, 20),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        wagon.shift(const Offset(0, 3)),
        Paint()..color = GamePalette.shade(_trainColors[train], .22),
      );
      canvas.drawRRect(
        wagon,
        Paint()..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_trainColors[train], Colors.white, .3)!,
            _trainColors[train],
          ],
        ).createShader(wagon.outerRect),
      );
      canvas.drawRRect(wagon, Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke);
      for (final offset in const [-7.0, 5.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(offset, -2),
              width: 8, height: 7),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFDDF4FF),
        );
      }
      canvas.drawCircle(const Offset(15, 0), 2.4,
          Paint()..color = const Color(0xFFFFF0A4));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.visualTime != visualTime ||
      oldDelegate.engine != engine ||
      engine.time > 0;
}
