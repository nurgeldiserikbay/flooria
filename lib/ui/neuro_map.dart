import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/neuron_progression.dart';
import 'game_glyph.dart';
import 'neuro_connection_svg.dart';
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

  static const double _baseMapWidth = 390;
  static const double _baseMapHeight = 620;
  // Hand-shaped positions keep the progression organic instead of reading as
  // a level grid. Topology remains in NeuronMapGraph; this is presentation only.
  static const _mapPositions = <String, Offset>{
    'node_01': Offset(.50, .06),
    'node_02': Offset(.22, .20),
    'node_03': Offset(.78, .22),
    'node_04': Offset(.08, .37),
    'node_05': Offset(.40, .39),
    'node_06': Offset(.91, .37),
    'node_07': Offset(.10, .55),
    'node_08': Offset(.31, .57),
    'node_09': Offset(.69, .56),
    'node_10': Offset(.91, .58),
    'node_11': Offset(.31, .76),
    'node_12': Offset(.70, .78),
    'node_13': Offset(.50, .94),
  };

  Offset _point(NeuronNode node, double width, double height) {
    final position = _mapPositions[node.id] ?? const Offset(.5, .5);
    final insetX = width * .075;
    final insetY = height * .045;
    return Offset(
      insetX + position.dx * (width - insetX * 2),
      insetY + position.dy * (height - insetY * 2),
    );
  }

  double _diameter(NeuronNode node, Set<String> completed) {
    final state = NeuronMapGraph.availability(node, completed);
    if (state == NeuronAvailability.open) return node.id == 'node_01' ? 76 : 68;
    if (state == NeuronAvailability.complete) return 66;
    return 54;
  }

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
    return LayoutBuilder(builder: (context, bounds) {
      const chromeHeight = 148.0;
      final viewportHeight = math.max(0.0, bounds.maxHeight - chromeHeight);
      // Keep the map larger than its viewport at its resting scale. This gives
      // pan gestures room to move the network even before the player zooms in.
      final mapWidth = math.max(_baseMapWidth, bounds.maxWidth * 1.25);
      final mapHeight = math.max(_baseMapHeight, viewportHeight * 1.18);
      final positions = {
        for (final node in nodes) node.id: _point(node, mapWidth, mapHeight),
      };
      if (!_positioned) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final scale = math.min(
            bounds.maxWidth / mapWidth,
            viewportHeight / mapHeight,
          ).clamp(.62, 1.0);
          _transform.value = Matrix4.identity()
            ..translateByDouble(
              (bounds.maxWidth - mapWidth * scale) / 2,
              (viewportHeight - mapHeight * scale) / 2,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        });
      }

      return Stack(children: [
        const Positioned.fill(child: _MapAtmosphere()),
        Positioned.fill(
          top: 66,
          bottom: 82,
          child: InteractiveViewer(
            transformationController: _transform,
            constrained: false,
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(240),
            minScale: .62,
            maxScale: 1.35,
            child: SizedBox(
              width: mapWidth,
              height: mapHeight,
              child: Stack(clipBehavior: Clip.none, children: [
                NeuroConnectionSvg(
                  width: mapWidth,
                  height: mapHeight,
                  nodes: nodes,
                  positions: positions,
                  completed: widget.completedNeurons,
                ),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => CustomPaint(
                    size: Size(mapWidth, mapHeight),
                    painter: NeuroFlowParticles(
                      nodes: nodes,
                      positions: positions,
                      completed: widget.completedNeurons,
                      phase: _pulse.value,
                    ),
                  ),
                ),
                for (final node in nodes)
                  Builder(builder: (context) {
                    final point = positions[node.id]!;
                    final diameter = _diameter(node, widget.completedNeurons);
                    return Positioned(
                      left: point.dx - diameter / 2,
                      top: point.dy - diameter / 2,
                      width: diameter,
                      height: diameter,
                      child: _NeuronDot(
                        key: ValueKey(node.id),
                        node: node,
                        state: NeuronMapGraph.availability(
                          node, widget.completedNeurons),
                        pulse: _pulse,
                        onTap: widget.onNodeTap,
                      ),
                    );
                  }),
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
    final open = state == NeuronAvailability.open;
    final icon = node.id == 'node_01' && node.moduleId == null
        ? Icons.play_arrow_rounded
        : node.moduleId == null
            ? Icons.hub_rounded
            : GameGlyphs.iconFor(node.moduleId!);
    final glow = .5 + .5 * math.sin(pulse.value * math.pi * 2);
    final size = node.id == 'node_01' && open ? 76.0 : open ? 68.0 : complete ? 66.0 : 54.0;
    final color = complete
        ? const Color(0xFF53B99F)
        : const Color(0xFF716BE0);
    final lockedTints = <(Color, Color)>[
      (const Color(0xFFD6E8FF), const Color(0xFFAAC8F0)),
      (const Color(0xFFE5DDFF), const Color(0xFFC2B6F0)),
      (const Color(0xFFD4F1EA), const Color(0xFFA8D8CB)),
      (const Color(0xFFFFE5D8), const Color(0xFFF3C4B1)),
    ];
    final lockedTint = lockedTints[(node.slot - 1) % lockedTints.length];
    return Semantics(
      label: 'Node ${node.slot}, level ${node.level}, ${locked ? "locked" : complete ? "complete" : "open"}',
      button: !locked,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) => Transform.scale(
          scale: open ? 1 + .018 * glow : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: locked ? null : () => onTap(node),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: locked
                      ? const RadialGradient(
                          center: Alignment(-.25, -.35),
                          colors: [lockedTint.$1, lockedTint.$2],
                        )
                      : complete
                          ? const RadialGradient(
                              center: Alignment(-.3, -.45),
                              colors: [Color(0xFFD8FFF0), Color(0xFF7CD4B6)],
                            )
                          : const RadialGradient(
                              center: Alignment(-.3, -.45),
                              colors: [Color(0xFFC1B9FF), Color(0xFF716BE0)],
                            ),
                  border: Border.all(
                    color: locked
                        ? const Color(0x99FFFFFF)
                        : complete
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFF9F8FF),
                    width: open ? 3 : 2,
                  ),
                  boxShadow: [
                    if (open) BoxShadow(
                      color: color.withValues(alpha: .18 + glow * .13),
                      blurRadius: 18 + glow * 7,
                      spreadRadius: 3 + glow * 2,
                    ),
                    if (complete) const BoxShadow(
                      color: Color(0x4453B99F), blurRadius: 16,
                      offset: Offset(0, 5)),
                    if (!locked) const BoxShadow(
                      color: Color(0x22415382), blurRadius: 8,
                      offset: Offset(0, 5)),
                  ],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  if (open) Container(
                    width: size * .69,
                    height: size * .69,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .28), width: 1.2),
                    ),
                  ),
                  Icon(icon, size: open ? 29 : locked ? 21 : 25,
                    color: locked
                        ? const Color(0xFF536889)
                        : Colors.white),
                  if (complete) const Positioned(
                    right: 0, bottom: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFFFFFFFF),
                      child: Icon(Icons.check_rounded, size: 13,
                        color: Color(0xFF35A88C)),
                    ),
                  ),
                  if (locked) Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEAF0FA),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 10,
                        color: Color(0xFF8290A9)),
                    ),
                  ),
                  if (!complete && !locked) Positioned(
                    right: 1, top: 1,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF8F6FF),
                      ),
                      alignment: Alignment.center,
                      child: Text('${node.level}', style: const TextStyle(
                        color: Color(0xFF655BC2), fontSize: 9,
                        fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              ),
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
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8F6FF), Color(0xFFEBECFF), Color(0xFFFFF0E7)],
    ))),
    const Positioned(top: -135, left: -100,
      child: _AtmosphereOrb(size: 310, color: Color(0x6671C9EE))),
    const Positioned(top: 145, right: -175,
      child: _AtmosphereOrb(size: 360, color: Color(0x557A78E5))),
    const Positioned(bottom: -190, left: -115,
      child: _AtmosphereOrb(size: 360, color: Color(0x55F4BFA9))),
  ]);
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient:
      RadialGradient(colors: [color, color.withValues(alpha: 0)])),
  ));
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
