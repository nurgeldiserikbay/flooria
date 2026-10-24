import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'neuro_hub_pages.dart';

/// Lightweight neuron network: pure Flutter painting + existing SVG assets.
/// Nodes reuse the persisted floor number, so no saved games are lost.
class NeuroMapView extends StatefulWidget {
  const NeuroMapView({
    super.key,
    required this.floor,
    required this.onNodeTap,
    required this.onGames,
    required this.onAnalytics,
    required this.onRecords,
    required this.onSettings,
    this.motionEnabled = true,
  });
  final int floor;
  final ValueChanged<int> onNodeTap;
  final VoidCallback onGames;
  final VoidCallback onAnalytics;
  final VoidCallback onRecords;
  final VoidCallback onSettings;
  final bool motionEnabled;

  @override
  State<NeuroMapView> createState() => _NeuroMapViewState();
}

class _NeuroMapViewState extends State<NeuroMapView> {
  late final TransformationController _transform = TransformationController();
  int? selected;
  bool _positioned = false;

  // A repeatable organic path, with slight horizontal branching.
  List<Offset> get _points {
    final count = math.max(12, widget.floor + 5);
    return List<Offset>.generate(count, (i) => Offset(
      85.0 + ((i * 113 + 61) % 220).toDouble(),
      65.0 + i * 132.0,
    ));
  }

  @override
  void didUpdateWidget(covariant NeuroMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floor != widget.floor) _positioned = false;
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final visible = math.min(points.length, math.max(6, widget.floor + 4));
    final current = (widget.floor - 1).clamp(0, points.length - 1);
    return LayoutBuilder(builder: (context, constraints) {
      if (!_positioned) {
        _positioned = true;
        final target = points[current];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _transform.value = Matrix4.identity()
            ..translateByDouble(constraints.maxWidth / 2 - target.dx,
              constraints.maxHeight * .45 - target.dy - 80, 0, 1);
        });
      }
      return Stack(children: [
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14275B), Color(0xFF1B3977), Color(0xFF211A60)])))),
        Positioned.fill(child: InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(350),
          minScale: .65, maxScale: 2.1,
          child: SizedBox(width: 390, height: points.last.dy + 180,
            child: Stack(children: [
              CustomPaint(size: Size(390, points.last.dy + 180),
                painter: _Connections(points.take(visible).toList(),
                  widget.floor)),
              for (var i = 0; i < visible; i++)
                Positioned(
                  left: points[i].dx - 39,
                  top: points[i].dy + 45,
                  width: 78, height: 90,
                  child: Semantics(
                    label: 'Neuron ${i + 1}, ${i + 1 < widget.floor ? "completed" : i + 1 == widget.floor ? "current" : "locked"}',
                    button: i + 1 <= widget.floor,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(42),
                      onTap: () {
                        if (i + 1 > widget.floor) return;
                        setState(() => selected = i);
                        widget.onNodeTap(i + 1);
                      },
                      child: Column(children: [
                        SvgPicture.asset(
                          'assets/design/${i + 1 < widget.floor ? "neuro-node-active" : i + 1 == widget.floor ? "neuro-node-current" : "neuro-node-locked"}.svg',
                          height: 67, width: 67),
                        Text('${i + 1}', style: TextStyle(
                          color: i + 1 <= widget.floor ? Colors.white : const Color(0xFF8EA1CE),
                          fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              Positioned(
                left: points[current].dx - 21,
                top: points[current].dy + 16,
                child: IgnorePointer(child: SvgPicture.asset(
                  'assets/design/neuro-avatar-top.svg', width: 42, height: 42)),
              ),
            ]))),
        ),
        Positioned(top: 12, left: 18, right: 18,
          child: Row(children: [
            SvgPicture.asset('assets/design/neuro-brand-symbol.svg', width: 38),
            const SizedBox(width: 8),
            const Expanded(child: Text('NEURO', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              letterSpacing: 3, fontSize: 22))),
            Text('NODE ${widget.floor}', style: const TextStyle(
              color: Color(0xFFD4E4FF), fontWeight: FontWeight.w800)),
            IconButton(tooltip: 'Settings', onPressed: widget.onSettings,
              icon: const Icon(Icons.settings_rounded, color: Colors.white)),
          ])),
        Positioned(left: 22, right: 22, bottom: 93,
          child: Container(padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xE71A285B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x667D9FF7))),
            child: Row(children: [
              SvgPicture.asset('assets/design/neuro-icon-${widget.floor.isOdd ? "2048" : "sequence"}.svg',
                width: 45, height: 45),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT CHALLENGE', style: TextStyle(
                    color: Color(0xFFA9C2FC), fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text(widget.floor.isOdd ? '2048' : 'Number Trail',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 17, fontWeight: FontWeight.w900)),
                ])),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7765FC)),
                onPressed: () => widget.onNodeTap(widget.floor),
                child: const Text('PLAY')),
            ]))),
        Positioned(left: 0, right: 0, bottom: 0,
          child: NeuroNavigation(selected: 0, onTab: (tab) {
            switch (tab) {
              case 1: widget.onGames();
              case 2: widget.onAnalytics();
              case 3: widget.onRecords();
              default: break;
            }
          })),

      ]);
    });
  }


}

class _Connections extends CustomPainter {
  _Connections(this.nodes, this.floor);
  final List<Offset> nodes;
  final int floor;
  @override
  void paint(Canvas canvas, Size size) {
    // Connection painting is independent of game assets and stays sharp on zoom.
    for (var i = 1; i < nodes.length; i++) {
      final p = nodes[i - 1] + const Offset(0, 78);
      final q = nodes[i] + const Offset(0, 78);
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..cubicTo(p.dx + 68, p.dy - 42, q.dx - 68, q.dy + 42, q.dx, q.dy);
      canvas.drawPath(path, Paint()
        ..color = i < floor ? const Color(0xFF80DDEB) : const Color(0xFF4D679C)
        ..strokeWidth = i < floor ? 6 : 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _Connections oldDelegate) =>
      oldDelegate.floor != floor || oldDelegate.nodes.length != nodes.length;
}
