import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'pendulum_drop_engine.dart';

class PendulumDropPage extends StatefulWidget {
  const PendulumDropPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int hits, int attempts) onSessionEnd;

  @override
  State<PendulumDropPage> createState() => _PendulumDropPageState();
}

class _PendulumDropPageState extends State<PendulumDropPage>
    with SingleTickerProviderStateMixin {
  late PendulumDropSession game;
  late final Ticker _ticker;
  Duration? _lastTick;
  int revision = 0;
  bool reported = false;
  String message = 'Tap DROP at the right moment';

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker = createTicker(_onTick)..start();
  }

  void _reset() {
    game = PendulumDropSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 953 + revision);
    _lastTick = null;
    reported = false;
    message = 'Tap DROP at the right moment';
  }

  void _onTick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null || !mounted || game.finished) return;
    final landed = game.advance(
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond);
    if (landed) {
      message = game.lastShotHit
          ? (game.finished ? 'Perfect! All targets hit.' : 'Bullseye! Next target.')
          : 'Missed! Watch the swing and try again.';
    }
    setState(() {});
    if (landed && game.finished && !reported) {
      reported = true;
      _ticker.stop();
      widget.onSessionEnd(game.hits, game.attempts);
      if (widget.floor != null) widget.onComplete();
    }
  }

  void _drop() {
    if (!game.release()) return;
    setState(() => message = 'Flying toward the target...');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF344A7C);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF4F9FF),
        foregroundColor: ink,
        title: const Text('Pendulum Drop',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7086AD))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFCAECFA), Color(0xFFE5E4FD),
                Color(0xFFFFEBD9)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.motion_photos_on_rounded,
                  color: Color(0xFF6A82C1), size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Release the ball into the cup',
                  style: TextStyle(color: ink,
                      fontSize: 13, fontWeight: FontWeight.w900))),
              Text('${game.hits} / ${game.roundCount}',
                  style: const TextStyle(color: Color(0xFF6B71AA),
                      fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              return Center(child: AspectRatio(
                aspectRatio: 0.85,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xCFFFFFFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFAEC8E8), width: 2)),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    key: const ValueKey('pendulum-field'),
                    painter: _PendulumPainter(game),
                    child: const SizedBox.expand(),
                  ),
                ),
              ));
            })),
            const SizedBox(height: 9),
            Text(message, key: const ValueKey('pendulum-message'),
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w800, color: ink),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${game.attempts} drops',
                  style: const TextStyle(color: ink, fontSize: 13,
                      fontWeight: FontWeight.w900))),
              SizedBox(height: 48, child: FilledButton.icon(
                key: const ValueKey('pendulum-drop-button'),
                onPressed: game.finished
                    ? () => setState(() {
                        revision++;
                        _reset();
                        _ticker.start();
                      })
                    : game.flying ? null : _drop,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7774C8),
                    foregroundColor: Colors.white),
                icon: Icon(game.finished
                    ? Icons.refresh_rounded : Icons.arrow_downward_rounded),
                label: Text(game.finished ? 'PLAY AGAIN' : 'DROP',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              )),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() {
                  revision++;
                  _reset();
                  if (!_ticker.isActive) _ticker.start();
                }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
          ]),
        ),
      ))),
    );
  }
}

/// Simple normalized physics drawing, with no image dependencies.
class _PendulumPainter extends CustomPainter {
  const _PendulumPainter(this.session);
  final PendulumDropSession session;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldWidth = size.width;
    final scale = math.min(fieldWidth / 3.6, size.height / 2.0);
    final origin = Offset(fieldWidth / 2, size.height * 0.17);
    Offset pos(double x, double y) =>
        origin + Offset(x * scale, y * scale);

    final support = Paint()
      ..color = const Color(0xFF6E86B8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final ground = pos(0, PendulumDropSession.groundY).dy;
    canvas.drawLine(Offset(0, ground), Offset(size.width, ground),
        Paint()..color = const Color(0xFFABC8C7)
          ..strokeWidth = 5);
    final target = pos(session.targetX,
        PendulumDropSession.groundY);
    final cup = Paint()
      ..color = const Color(0xFFFFC96D)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cupPath = Path()
      ..moveTo(target.dx - 20, target.dy - 17)
      ..lineTo(target.dx - 15, target.dy + 9)
      ..quadraticBezierTo(target.dx, target.dy + 18,
          target.dx + 15, target.dy + 9)
      ..lineTo(target.dx + 20, target.dy - 17);
    canvas.drawPath(cupPath, cup);
    canvas.drawCircle(target + const Offset(0, -5), 4,
        Paint()..color = const Color(0xFFE69D46));
    final pivot = pos(0, 0);
    canvas.drawLine(Offset(pivot.dx - 36, pivot.dy - 20),
        Offset(pivot.dx + 36, pivot.dy - 20), support);
    if (!session.flying && !session.finished) {
      canvas.drawLine(pivot, pos(session.bobX, session.bobY),
          Paint()..color = const Color(0xFF8698BD)
            ..strokeWidth = 3);
    }
    canvas.drawCircle(pivot, 9,
        Paint()..color = const Color(0xFF7388B7));
    final bob = pos(session.bobX, session.bobY);
    if (!session.finished) {
      canvas.drawCircle(bob, 16, Paint()
        ..color = const Color(0xFF8DB9EF));
      canvas.drawCircle(bob + const Offset(-5, -5), 5,
          Paint()..color = const Color(0xCFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter oldDelegate) => true;
}
