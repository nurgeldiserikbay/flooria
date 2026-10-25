import 'dart:math';

import 'package:flutter/material.dart';

import 'neural_links_engine.dart';

class NeuralLinksPage extends StatefulWidget {
  const NeuralLinksPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  /// Reports elapsed milliseconds and node moves.
  final void Function(int elapsedMillis, int moves) onSessionEnd;

  @override
  State<NeuralLinksPage> createState() => _NeuralLinksPageState();
}

class _NeuralLinksPageState extends State<NeuralLinksPage> {
  late NeuralLinksSession session;
  final Stopwatch _clock = Stopwatch();
  int _revision = 0;
  int _paintVersion = 0;
  int _dragCount = 0;
  int? _draggedNode;
  bool _dragChanged = false;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _clock
      ..stop()
      ..reset();
    _rewarded = false;
    _draggedNode = null;
    _dragCount = 0;
    _dragChanged = false;
    session = NeuralLinksSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch + _revision++
          : widget.floor! * 15485863 + _revision++,
    );
  }

  void _startDrag(Offset point, double side) {
    var closestDistance = 34.0;
    int? closest;
    for (var index = 0; index < session.positions.length; index++) {
      final node = session.positions[index];
      final distance = (Offset(node.x * side, node.y * side) - point).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = index;
      }
    }
    if (closest != null) {
      if (!_clock.isRunning) _clock.start();
      setState(() {
        _draggedNode = closest;
        _dragChanged = false;
      });
      _moveDragged(point, side);
    }
  }

  void _moveDragged(Offset point, double side) {
    final index = _draggedNode;
    if (index == null || session.finished || side <= 0) return;
    final moved = session.moveNode(index, point.dx / side, point.dy / side);
    if (!moved) return;
    _dragChanged = true;
    setState(() => _paintVersion++);
    if (session.finished) {
      _recordDrag();
      _finish();
    }
  }

  void _recordDrag() {
    if (!_dragChanged) return;
    _dragCount++;
    _dragChanged = false;
  }

  Future<void> _finish() async {
    if (_rewarded) return;
    _rewarded = true;
    _clock.stop();
    widget.onSessionEnd(_clock.elapsedMilliseconds, _dragCount);
    if (widget.floor == null) return;
    widget.onComplete();
    final advance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Network connected!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text('You cleared every crossing in ${_clock.elapsedMilliseconds ~/ 1000}s.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('CONTINUE'),
        )],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(advance == true);
  }

  @override
  Widget build(BuildContext context) {
    final crossed = session.crossingCount;
    final complete = session.finished;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Neural Links', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _cream,
        foregroundColor: _ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: _muted)),
            )),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.hub_rounded, color: _teal, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Move neurons until no links cross',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink, fontSize: 14))),
              Text(complete ? 'CLEAR' : '$crossed crossings', style: TextStyle(
                color: complete ? _green : _teal, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: complete ? 1 : 0,
              minHeight: 7,
              backgroundColor: const Color(0xFFD9ECE7),
              color: _teal,
            )),
            const SizedBox(height: 12),
            Expanded(child: Center(child: LayoutBuilder(builder: (context, bounds) {
              final side = min(bounds.maxWidth, bounds.maxHeight);
              return Semantics(
                label: complete
                    ? 'Neural link puzzle complete'
                    : 'Network with $crossed crossing links. Drag the colored nodes to untangle them.',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => _startDrag(details.localPosition, side),
                  onPanUpdate: (details) => _moveDragged(details.localPosition, side),
                  onPanEnd: (_) => setState(() {
                    _recordDrag();
                    _draggedNode = null;
                  }),
                  child: SizedBox.square(dimension: side, child: CustomPaint(
                    key: const ValueKey('neural-graph'),
                    painter: _NeuralGraphPainter(
                      session: session,
                      highlightedLinks: session.crossingLinkIndices,
                      draggedNode: _draggedNode,
                      version: _paintVersion,
                    ),
                    child: const SizedBox.expand(),
                  )),
                ),
              );
            }))),
            const SizedBox(height: 10),
            Text(complete
                ? 'Every connection is clear.'
                : 'Drag a glowing neuron to a new place.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('$_dragCount neuron drags', style: const TextStyle(
                fontSize: 12, color: _muted, fontWeight: FontWeight.w700))),
              if (complete && widget.floor == null)
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _startSession();
                    _paintVersion++;
                  }),
                  style: FilledButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('PLAY AGAIN'),
                ),
            ]),
          ]),
        ),
      ))),
    );
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }
}

class _NeuralGraphPainter extends CustomPainter {
  const _NeuralGraphPainter({
    required this.session,
    required this.highlightedLinks,
    required this.draggedNode,
    required this.version,
  });
  final NeuralLinksSession session;
  final Set<int> highlightedLinks;
  final int? draggedNode;
  final int version;

  static const _nodeColors = <Color>[
    Color(0xFFE9A16C), Color(0xFF81B9A6), Color(0xFF9C8BCB),
    Color(0xFFE28C92), Color(0xFF78ABC2), Color(0xFFC4A65E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final points = session.positions.map((point) => Offset(
      point.x * size.width,
      point.y * size.height,
    )).toList();
    final normalPaint = Paint()
      ..color = const Color(0xFFB9CFC8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final crossedPaint = Paint()
      ..color = const Color(0xFFE99278)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < session.links.length; index++) {
      final link = session.links[index];
      canvas.drawLine(points[link.from], points[link.to],
        highlightedLinks.contains(index) ? crossedPaint : normalPaint);
    }
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final color = _nodeColors[index % _nodeColors.length];
      if (draggedNode == index) {
        canvas.drawCircle(point, 27, Paint()..color = color.withValues(alpha: 0.18));
      }
      canvas.drawCircle(point, 21, Paint()..color = Colors.white);
      canvas.drawCircle(point, 17, Paint()..color = color);
      final text = TextPainter(
        text: TextSpan(text: '${index + 1}', style: const TextStyle(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralGraphPainter oldDelegate) =>
      version != oldDelegate.version ||
      draggedNode != oldDelegate.draggedNode ||
      highlightedLinks.length != oldDelegate.highlightedLinks.length;
}

const _cream = Color(0xFFFFF4E5);
const _ink = Color(0xFF76513D);
const _muted = Color(0xFF9B7B69);
const _teal = Color(0xFF70A99A);
const _green = Color(0xFF6DA986);
