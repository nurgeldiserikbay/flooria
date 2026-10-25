import '../core/game_registry.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'neuro_hub_pages.dart';
import '../game/floor_engine.dart';

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
  bool _positioned = false;

  // A repeatable organic path, with slight horizontal branching.
  List<Offset> get _points {
    final count = math.max(12, widget.floor + 5);
    return List<Offset>.generate(count, (i) => Offset(
      <double>[190, 95, 270, 315, 145, 70, 225, 310][i % 8],
      130.0 + i * 134.0,
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
        const Positioned.fill(child: NeuroAtmosphere(child: SizedBox.expand())),
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
                        widget.onNodeTap(i + 1);
                      },
                      child: Column(children: [
                        SvgPicture.asset(
                          'assets/design/${i + 1 < widget.floor ? "neuro-node-active" : i + 1 == widget.floor ? "neuro-node-current" : "neuro-node-locked"}.svg',
                          height: 67, width: 67),
                        Text('${i + 1}', style: TextStyle(
                          color: i + 1 <= widget.floor ? const Color(0xFF263F75) : const Color(0xFF7786AA),
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
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEURO', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 22)),
                Text('EXPLORE THE NETWORK', style: TextStyle(color: Color(0xFF9CE6FF),
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
              ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xDFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA0B6E5))),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                color: Color(0xFFFFE39D), fontWeight: FontWeight.w900))),
            IconButton(tooltip: 'Settings', onPressed: widget.onSettings,
              icon: const Icon(Icons.settings_rounded, color: Color(0xFF334A88))),
          ])),
        Positioned(left: 17, right: 17, bottom: 96,
          child: Container(padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFDFEFF), Color(0xFFE3EDFF)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFACC2F2)),
              boxShadow: const [BoxShadow(color: Color(0x446B86CC), blurRadius: 25, offset: Offset(0, 6))]),
            child: Row(children: [
              SvgPicture.asset('assets/design/neuro-icon-${GameRegistry.byId(const FloorEngine().challengeFor(widget.floor).gameId).icon}.svg',
                width: 45, height: 45),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR NEXT CHALLENGE', style: TextStyle(
                    color: Color(0xFFA9C2FC), fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text(GameRegistry.byId(const FloorEngine().challengeFor(widget.floor).gameId).title,
                    style: const TextStyle(color: Color(0xFF273F78),
                      fontSize: 17, fontWeight: FontWeight.w900)),
                ])),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFD15E),
                  foregroundColor: const Color(0xFF1C285D)),
                onPressed: () => widget.onNodeTap(widget.floor),
                label: const Text('PLAY')),
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
    // Procedural scattered synapses, not a repeated bitmap background.
    for (var i = 0; i < 120; i++) {
      final x = ((i * 97 + 23) % 390).toDouble();
      final y = ((i * 173 + 61) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.8 : .8,
        Paint()..color = const Color(0x666BBBEA));
    }
    for (var i = 0; i < nodes.length; i++) {
      final p = nodes[i] + const Offset(0, 78);
      final side = i.isEven ? -1.0 : 1.0;
      final end = Offset((p.dx + side * 82).clamp(25.0, 365.0), p.dy - 68);
      canvas.drawPath(Path()..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(p.dx + side * 65, p.dy - 9, end.dx, end.dy),
        Paint()..style = PaintingStyle.stroke
          ..strokeWidth = 1.6..color = const Color(0x887692CA));
      canvas.drawCircle(end, 7, Paint()..color = const Color(0x886A9BD7));
      canvas.drawCircle(end, 3, Paint()..color = const Color(0xFF527AC1));
      if (i == 0) continue;
      final start = nodes[i - 1] + const Offset(0, 78);
      final path = Path()..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + 18, start.dy + 65,
          p.dx - 18, p.dy - 65, p.dx, p.dy);
      final passed = i < floor;
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke
        ..strokeWidth = passed ? 10 : 6
        ..color = passed ? const Color(0x9970D3E8) : const Color(0x556E87BE));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round..strokeWidth = passed ? 3.6 : 2.3
        ..color = passed ? const Color(0xFF29B7CF) : const Color(0xFF819ACA));
    }
  }

  @override
  bool shouldRepaint(covariant _Connections oldDelegate) =>
      oldDelegate.floor != floor || oldDelegate.nodes.length != nodes.length;
}
