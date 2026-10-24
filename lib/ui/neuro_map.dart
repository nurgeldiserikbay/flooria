import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lightweight neuron network: pure Flutter painting + existing SVG assets.
/// Nodes reuse the persisted floor number, so no saved games are lost.
class NeuroMapView extends StatefulWidget {
  const NeuroMapView({
    super.key,
    required this.floor,
    required this.onNodeTap,
    required this.onGames,
    required this.onAnalytics,
    required this.onSettings,
    this.motionEnabled = true,
  });
  final int floor;
  final ValueChanged<int> onNodeTap;
  final VoidCallback onGames;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;
  final bool motionEnabled;

  @override
  State<NeuroMapView> createState() => _NeuroMapViewState();
}

class _NeuroMapViewState extends State<NeuroMapView> {
  late final TransformationController _transform = TransformationController();
  int? selected;

  // A repeatable organic path, with slight horizontal branching.
  static const _points = <Offset>[
    Offset(196, 560), Offset(103, 430), Offset(260, 320),
    Offset(132, 210), Offset(308, 105), Offset(205, -30),
    Offset(85, -155), Offset(280, -265), Offset(155, -395),
    Offset(325, -525), Offset(115, -640), Offset(225, -765),
  ];

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = math.min(_points.length, math.max(6, widget.floor + 4));
    final current = (widget.floor - 1).clamp(0, _points.length - 1);
    return LayoutBuilder(builder: (context, constraints) {
      final scale = math.min(1.0, constraints.maxWidth / 390);
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
          child: SizedBox(width: 390, height: 800,
            child: Stack(children: [
              CustomPaint(size: const Size(390, 800),
                painter: _Connections(_points.take(visible).toList(),
                  widget.floor)),
              for (var i = 0; i < visible; i++)
                Positioned(
                  left: _points[i].dx - 39,
                  top: _points[i].dy + 45,
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
                left: _points[current].dx - 21,
                top: _points[current].dy + 16,
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
        Positioned(left: 18, right: 18, bottom: 12,
          child: Container(height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xF01B295A),
              border: Border.all(color: const Color(0x776583D6))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _nav('neuro-nav-map.svg', 'Map', () {}),
                _nav('neuro-nav-games.svg', 'Games', widget.onGames),
                _nav('neuro-nav-analytics.svg', 'Skills', widget.onAnalytics),
              ]))),
      ]);
    });
  }

  Widget _nav(String icon, String label, VoidCallback callback) =>
      InkWell(onTap: callback, borderRadius: BorderRadius.circular(15),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.asset('assets/design/$icon', width: 25, height: 25),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ])));
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
