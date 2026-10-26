import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/neuron_progression.dart';
import 'game_glyph.dart';
import 'neuro_hub_pages.dart';

/// Branching, pannable progression map. The graph stays data-only in
/// [NeuronMapGraph]; this widget only paints and routes user input.
class NeuroMapView extends StatefulWidget {
  const NeuroMapView({
    super.key,
    required this.completedNeurons,
    required this.onNodeTap,
    required this.onGames,
    required this.onAnalytics,
    required this.onSettings,
    this.motionEnabled = true,
  });

  final Set<String> completedNeurons;
  final ValueChanged<NeuronNode> onNodeTap;
  final VoidCallback onGames;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;
  final bool motionEnabled;

  @override
  State<NeuroMapView> createState() => _NeuroMapViewState();
}

class _NeuroMapViewState extends State<NeuroMapView>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transform = TransformationController();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _positioned = false;

  static const double _mapWidth = 560;
  static const double _columnGap = 110;
  static const double _rowGap = 125;
  static const double _topInset = 52;
  static const double _nodeSize = 62;

  double _x(NeuronNode node) => 58 + node.column * _columnGap;
  double _y(NeuronNode node) => _topInset + node.row * _rowGap;

  @override
  void initState() {
    super.initState();
    if (widget.motionEnabled) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant NeuroMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionEnabled != widget.motionEnabled) {
      if (widget.motionEnabled) {
        _pulse.repeat();
      } else {
        _pulse.stop();
        _pulse.value = .5;
      }
    }
    if (oldWidget.completedNeurons.length != widget.completedNeurons.length) {
      _positioned = false;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = NeuronMapGraph.nodes;
    final mapHeight = _topInset + (nodes.last.row + 1) * _rowGap + 48;
    final openCount = nodes.where((node) => NeuronMapGraph.availability(
      node, widget.completedNeurons) != NeuronAvailability.locked).length;

    return LayoutBuilder(builder: (context, bounds) {
      if (!_positioned) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final scale = (bounds.maxWidth / _mapWidth).clamp(.62, .94);
          _transform.value = Matrix4.identity()
            ..translateByDouble(
              (bounds.maxWidth - _mapWidth * scale) / 2,
              8,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        });
      }

      return Stack(children: [
        const Positioned.fill(child: _MapAtmosphere()),
        Positioned.fill(
          top: 78,
          bottom: 88,
          child: InteractiveViewer(
            transformationController: _transform,
            constrained: false,
            boundaryMargin: const EdgeInsets.fromLTRB(80, 80, 80, 130),
            minScale: .5,
            maxScale: 1.45,
            child: SizedBox(
              width: _mapWidth,
              height: mapHeight,
              child: Stack(clipBehavior: Clip.none, children: [
                CustomPaint(
                  size: Size(_mapWidth, mapHeight),
                  painter: _SynapsePainter(
                    nodes: nodes,
                    completed: widget.completedNeurons,
                    x: _x,
                    y: _y,
                  ),
                ),
                for (final node in nodes)
                  Positioned(
                    left: _x(node) - _nodeSize / 2,
                    top: _y(node) - _nodeSize / 2,
                    width: _nodeSize,
                    height: _nodeSize,
                    child: _NeuronDot(
                      key: ValueKey(node.id),
                      node: node,
                      state: NeuronMapGraph.availability(
                        node, widget.completedNeurons),
                      pulse: _pulse,
                      onTap: widget.onNodeTap,
                    ),
                  ),
              ]),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 18,
          right: 18,
          child: Row(children: [
            const _BrandMark(),
            const SizedBox(width: 10),
            const Expanded(child: Text('NEURO PLAYGROUND',
              style: TextStyle(color: Color(0xFF314064),
                fontSize: 13, fontWeight: FontWeight.w900,
                letterSpacing: 1.2))),
            _ProgressPill(value: '${widget.completedNeurons.length} / ${nodes.length}'),
            const SizedBox(width: 3),
            IconButton(
              tooltip: 'Settings',
              onPressed: widget.onSettings,
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF41517A)),
            ),
          ]),
        ),
        Positioned(
          left: 20,
          bottom: 90,
          child: IgnorePointer(child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: openCount == 1 ? .74 : 0,
            child: const Text('FIRST SPARK', style: TextStyle(
              color: Color(0xFF52658E), fontSize: 9,
              letterSpacing: 1.8, fontWeight: FontWeight.w900)),
          )),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: NeuroNavigation(selected: 0, onTab: (tab) {
            switch (tab) {
              case 1: widget.onGames();
              case 2: widget.onAnalytics();
              case 3: widget.onAnalytics();
              default: break;
            }
          }),
        ),
      ]);
    });
  }
}

class _NeuronDot extends StatelessWidget {
  const _NeuronDot({
    super.key,
    required this.node,
    required this.state,
    required this.pulse,
    required this.onTap,
  });

  final NeuronNode node;
  final NeuronAvailability state;
  final Animation<double> pulse;
  final ValueChanged<NeuronNode> onTap;

  @override
  Widget build(BuildContext context) {
    final locked = state == NeuronAvailability.locked;
    final complete = state == NeuronAvailability.complete;
    final icon = GameGlyphs.iconFor(node.moduleId ?? 'slot');
    return Semantics(
      label: 'Node ${node.slot}, level ${node.level}, ${locked ? "locked" : complete ? "complete" : "open"}',
      button: !locked,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final glow = state == NeuronAvailability.open
              ? .18 + (math.sin(pulse.value * math.pi * 2) + 1) * .08
              : 0.0;
          return Transform.scale(
            scale: locked ? 1 : 1 + glow * .05,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: locked ? null : () => onTap(node),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked
                    ? const Color(0xFF39445D)
                    : complete
                        ? const Color(0xFFB7F2DE)
                        : const Color(0xFFFAFBFF),
                border: Border.all(
                  color: locked
                      ? const Color(0xFF58627A)
                      : complete
                          ? const Color(0xFF57BEA0)
                          : const Color(0xFFFFFFFF),
                  width: 3,
                ),
                boxShadow: [
                  if (!locked) BoxShadow(
                    color: complete
                        ? const Color(0x5557BEA0)
                        : const Color(0x5575C7FF),
                    blurRadius: complete ? 17 : 20,
                    spreadRadius: complete ? 1 : 3,
                  ),
                ],
              ),
              child: Stack(alignment: Alignment.center, children: [
                Icon(icon, size: 27, color: locked
                    ? const Color(0xFF78839B)
                    : const Color(0xFF5364A3)),
                if (complete) const Positioned(
                  right: 1, bottom: 1,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xFF55BDA0),
                    child: Icon(Icons.check_rounded, size: 13,
                      color: Colors.white),
                  ),
                ),
                if (!complete && !locked) Positioned(
                  right: 4, bottom: 3,
                  child: Text('${node.level}', style: const TextStyle(
                    color: Color(0xFF6675A8), fontSize: 9,
                    fontWeight: FontWeight.w900)),
                ),
                if (locked) const Icon(Icons.lock_rounded,
                  size: 14, color: Color(0xFFABB3C5)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapAtmosphere extends StatelessWidget {
  const _MapAtmosphere();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE9F5FF), Color(0xFFE9EAFE), Color(0xFFF6EFFA)],
    )),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    height: 37,
    width: 37,
    decoration: BoxDecoration(
      color: const Color(0xFF5468B3),
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [BoxShadow(color: Color(0x335468B3),
        blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 21),
  );
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xCCFFFFFF),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFC7D3EF)),
    ),
    child: Text(value, style: const TextStyle(
      color: Color(0xFF52628E), fontSize: 10,
      fontWeight: FontWeight.w900)),
  );
}

class _SynapsePainter extends CustomPainter {
  const _SynapsePainter({
    required this.nodes,
    required this.completed,
    required this.x,
    required this.y,
  });

  final List<NeuronNode> nodes;
  final Set<String> completed;
  final double Function(NeuronNode) x;
  final double Function(NeuronNode) y;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final node in nodes) node.id: node};
    for (var i = 0; i < 82; i++) {
      final px = ((i * 137 + 29) % size.width.toInt()).toDouble();
      final py = ((i * 191 + 43) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(px, py), i.isEven ? 1 : 1.8,
        Paint()..color = const Color(0x224C67A0));
    }
    for (final node in nodes) {
      for (final parentId in node.parents) {
        final parent = byId[parentId];
        if (parent == null) continue;
        final start = Offset(x(parent), y(parent));
        final end = Offset(x(node), y(node));
        final path = Path()
          ..moveTo(start.dx, start.dy + 29)
          ..cubicTo(start.dx, start.dy + 76,
              end.dx, end.dy - 76, end.dx, end.dy - 29);
        final passed = completed.contains(parent.id) && completed.contains(node.id);
        final open = completed.contains(parent.id);
        final color = passed
            ? const Color(0xFF64BFA8)
            : open
                ? const Color(0xFF9DADE0)
                : const Color(0x333C4B6C);
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = passed ? 4.2 : open ? 3 : 2.4
          ..strokeCap = StrokeCap.round
          ..color = color);
        if (open) {
          final middle = Offset((start.dx + end.dx) / 2,
              (start.dy + end.dy) / 2);
          canvas.drawCircle(middle, 3.2, Paint()..color = color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SynapsePainter oldDelegate) =>
      oldDelegate.completed.length != completed.length ||
      oldDelegate.nodes.length != nodes.length;
}
