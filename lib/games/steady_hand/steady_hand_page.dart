import 'package:flutter/material.dart';

import 'steady_hand_engine.dart';

class SteadyHandPage extends StatefulWidget {
  const SteadyHandPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int completedTrails, int mistakes) onSessionEnd;

  @override
  State<SteadyHandPage> createState() => _SteadyHandPageState();
}

class _SteadyHandPageState extends State<SteadyHandPage> {
  static const _paper = Color(0xFFF5F8FF);
  static const _ink = Color(0xFF35466B);
  static const _muted = Color(0xFF7A87A5);
  static const _teal = Color(0xFF4CAFA5);

  late SteadyHandSession session;
  int _revision = 0;
  bool _reported = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _reported = false;
    _notice = null;
    session = SteadyHandSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 104729 + _revision++,
      level: widget.floor ?? 1,
    );
  }

  void _begin(Offset local, Size size) {
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    if (session.begin(x, y)) {
      setState(() => _notice = null);
    } else {
      setState(() => _notice = 'Start from the green gate.');
    }
  }

  void _move(Offset local, Size size) {
    final previousRound = session.round;
    final result = session.move(local.dx / size.width, local.dy / size.height);
    if (result == TrailMoveResult.ignored) return;
    setState(() {
      _notice = result == TrailMoveResult.leftLane
          ? session.finished
              ? 'Trail missed. Keep going!'
              : session.round > previousRound
                  ? 'Trail missed. Next trail…'
                  : 'Out of lane. Trace it again.'
          : null;
    });
    if (session.finished) _finish();
  }

  void _end() {
    if (!session.active) return;
    final previousRound = session.round;
    final complete = session.end();
    setState(() {
      _notice = complete
          ? 'Nice control!'
          : session.finished
              ? 'Trail missed. Keep going!'
              : session.round > previousRound
                  ? 'Trail missed. Next trail…'
                  : 'Not quite. Try the same trail again.';
    });
    if (session.finished) _finish();
  }

  void _finish() {
    if (_reported || !session.finished) return;
    _reported = true;
    widget.onSessionEnd(session.completed, session.mistakes);
    if (session.passed && widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final complete = session.finished;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Steady Hand',
            style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: _ink,
        backgroundColor: _paper,
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('LEVEL ${widget.floor}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _muted)),
              ),
            ),
          IconButton(
            tooltip: 'Restart session',
            onPressed: () => setState(_startSession),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gesture_rounded,
                          color: _teal, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Trace the lane without crossing its edge.',
                            style: TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                      Text(
                        complete
                            ? '${session.completed} / 5'
                            : '${session.round + 1} / 5',
                        style: const TextStyle(
                            color: _teal, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.round / SteadyHandSession.roundCount,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFDDEAEF),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: complete
                        ? _ResultsPanel(
                            session: session,
                            onRetry: () => setState(_startSession),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final canvasSize = Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    );
                                    return GestureDetector(
                                      key: const ValueKey('steady-hand-canvas'),
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: (details) =>
                                          _begin(details.localPosition, canvasSize),
                                      onPanUpdate: (details) =>
                                          _move(details.localPosition, canvasSize),
                                      onPanEnd: (_) => _end(),
                                      child: Container(
                                        width: canvasSize.width,
                                        height: canvasSize.height,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                              color: const Color(0xFFDCE6F3)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x0C35466B),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: CustomPaint(
                                          painter: _TrailPainter(
                                            round: session.current,
                                            cursor: session.cursor,
                                            active: session.active,
                                          ),
                                          size: canvasSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    session.active
                                        ? Icons.front_hand_rounded
                                        : Icons.touch_app_rounded,
                                    color: _teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _notice ?? 'Touch the green start and drag to the finish.',
                                      style: const TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    'TRIES ${session.attemptsLeft}',
                                    style: const TextStyle(
                                        color: _teal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trails cleared: ${session.completed}   •   Mistakes: ${session.mistakes}',
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.round,
    required this.cursor,
    required this.active,
  });

  final SteadyHandRound round;
  final TrailPoint? cursor;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final lane = Path();
    for (var index = 0; index < round.points.length; index++) {
      final point = round.points[index];
      final offset = Offset(point.x * size.width, point.y * size.height);
      if (index == 0) {
        lane.moveTo(offset.dx, offset.dy);
      } else {
        lane.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.drawPath(
      lane,
      Paint()
        ..color = const Color(0xFFE5F5F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = round.halfWidth * 2 * size.height
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      lane,
      Paint()
        ..color = const Color(0xFFB8DED9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final start = Offset(
      SteadyHandRound.startX * size.width,
      round.centerYAt(SteadyHandRound.startX) * size.height,
    );
    final finish = Offset(
      SteadyHandRound.finishX * size.width,
      round.centerYAt(SteadyHandRound.finishX) * size.height,
    );
    canvas.drawCircle(start, 11, Paint()..color = const Color(0xFF53B996));
    canvas.drawCircle(finish, 11, Paint()..color = const Color(0xFFF2B64B));
    canvas.drawCircle(start, 4, Paint()..color = Colors.white);
    canvas.drawCircle(finish, 4, Paint()..color = Colors.white);

    final point = cursor;
    if (active && point != null) {
      canvas.drawCircle(
        Offset(point.x * size.width, point.y * size.height),
        13,
        Paint()..color = const Color(0xCC6F82DA),
      );
      canvas.drawCircle(
        Offset(point.x * size.width, point.y * size.height),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.round != round ||
      oldDelegate.cursor != cursor ||
      oldDelegate.active != active;
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.session, required this.onRetry});

  final SteadyHandSession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFDCE6F3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                session.passed ? Icons.stars_rounded : Icons.replay_rounded,
                color: session.passed
                    ? const Color(0xFFF0B64D)
                    : const Color(0xFF4CAFA5),
                size: 46,
              ),
              const SizedBox(height: 10),
              Text(
                session.passed ? 'Steady all the way!' : 'Give it another try',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF35466B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'You cleared ${session.completed} of ${SteadyHandSession.roundCount} trails with ${session.mistakes} misses.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF7A87A5), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('PLAY AGAIN'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAFA5),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
}
