import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _animating = false;

  static const double _baseMapWidth = 640;
  static const double _baseMapHeight = 2450;
  // Hand-shaped positions keep the progression organic instead of reading as
  // a level grid. Topology remains in NeuronMapGraph; this is presentation only.
  // Fixed, irregular anchors avoid a repeated pattern and stay stable during rebuilds.
  static const _fogAnchors =
      <(String, String, double, double, double, double)>[
    ('node_02', 'assets/fog/fog_01.png', .54, .23, .38, -.28),
    ('node_06', 'assets/fog/fog_02.png', .52, .22, .34, .42),
    ('node_08', 'assets/fog/fog_03.png', .58, .24, .42, -.16),
    ('node_12', 'assets/fog/fog_04.png', .56, .23, .36, .31),
  ];

  // Four separate branch silhouettes soften the map's structure. Their fixed
  // positions and varied rotations keep the layout organic across rebuilds.
  static const _dendriteAnchors = <(String, double, double, double, double, double)>[
    ('assets/dendrites/dendrite_01.svg', .18, .29, .38, .24, -.18),
    ('assets/dendrites/dendrite_02.svg', .79, .30, .38, .22, .46),
    ('assets/dendrites/dendrite_03.svg', .20, .68, .38, .23, -.34),
    ('assets/dendrites/dendrite_04.svg', .80, .67, .38, .25, .28),
  ];

  static const _mapPositions = <String, Offset>{
    'node_01': Offset(.50, .05),
    'node_02': Offset(.22, .10),
    'node_03': Offset(.78, .11),
    'node_04': Offset(.08, .16),
    'node_05': Offset(.40, .17),
    'node_06': Offset(.91, .16),
    'node_07': Offset(.10, .22),
    'node_08': Offset(.31, .23),
    'node_09': Offset(.69, .23),
    'node_10': Offset(.91, .24),
    'node_11': Offset(.31, .30),
    'node_12': Offset(.70, .30),
    'node_13': Offset(.50, .37),
    'node_14': Offset(.22, .43),
    'node_15': Offset(.78, .43),
    'node_16': Offset(.50, .49),
    'node_17': Offset(.23, .55),
    'node_18': Offset(.77, .55),
    // Organic rows keep 55 nodes distinct, without overlapping the
    // 39–48 group at the bottom of the map.
    'node_19': Offset(.09, .59),
    'node_20': Offset(.30, .60),
    'node_21': Offset(.52, .60),
    'node_22': Offset(.73, .59),
    'node_23': Offset(.91, .61),
    'node_24': Offset(.07, .66),
    'node_25': Offset(.28, .67),
    'node_26': Offset(.49, .66),
    'node_27': Offset(.70, .67),
    'node_28': Offset(.92, .66),
    'node_29': Offset(.10, .72),
    'node_30': Offset(.32, .73),
    'node_31': Offset(.53, .73),
    'node_32': Offset(.75, .72),
    'node_33': Offset(.91, .73),
    'node_34': Offset(.08, .78),
    'node_35': Offset(.29, .79),
    'node_36': Offset(.49, .78),
    'node_37': Offset(.71, .79),
    'node_38': Offset(.90, .79),
    'node_39': Offset(.10, .84),
    'node_40': Offset(.32, .85),
    'node_41': Offset(.53, .84),
    'node_42': Offset(.74, .85),
    'node_43': Offset(.92, .84),
    'node_44': Offset(.08, .90),
    'node_45': Offset(.29, .91),
    'node_46': Offset(.49, .90),
    'node_47': Offset(.70, .91),
    'node_48': Offset(.90, .90),
    'node_49': Offset(.10, .96),
    'node_50': Offset(.31, .97),
    'node_51': Offset(.53, .96),
    'node_52': Offset(.74, .97),
    'node_53': Offset(.91, .96),
    'node_54': Offset(.37, .995),
    'node_55': Offset(.63, .995),
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
    if (state == NeuronAvailability.complete) return 62;
    return 49;
  }

  @override
  void initState() {
    super.initState();
    // A MediaQuery is not yet available in initState. Start the animation
    // when dependencies become available, and never tick under reduced motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animate = widget.motionEnabled && !reducedMotion;
    if (_animating == animate) return;
    _animating = animate;
    if (animate) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = .5;
    }
  }

  @override
  void didUpdateWidget(covariant NeuroMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    // The next reachable neuron may change when progress is recorded.
    if (!widget.completedNeurons.containsAll(oldWidget.completedNeurons) ||
        oldWidget.completedNeurons.length != widget.completedNeurons.length) {
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
      const chromeHeight = 126.0;
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
          // At launch there must be space to drag *horizontally* without
          // zooming first. Scale to roughly 125% of viewport width.
          final scale = (bounds.maxWidth / mapWidth * 1.25)
              .clamp(.72, .90);
          // Open on the next playable node rather than the empty middle
          // of a tall graph. The rest of the world remains freely pannable.
          final focus = nodes.firstWhere(
            (node) => NeuronMapGraph.availability(
              node, widget.completedNeurons) == NeuronAvailability.open,
            orElse: () => nodes.first,
          );
          final focusPoint = positions[focus.id]!;
          _transform.value = Matrix4.identity()
            ..translateByDouble(
              (bounds.maxWidth / 2) - focusPoint.dx * scale,
              viewportHeight * .28 - focusPoint.dy * scale,
              0, 1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        });
      }

      return Stack(children: [
        Positioned.fill(
          top: 122,
          bottom: 4,
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
                const Positioned.fill(child: RepaintBoundary(
                  child: _MapAtmosphere(),
                )),
                for (final fog in _fogAnchors)
                  if (NeuronMapGraph.availability(
                    nodes.firstWhere((node) => node.id == fog.$1),
                    widget.completedNeurons,
                  ) == NeuronAvailability.locked)
                    Positioned(
                      left: positions[fog.$1]!.dx - mapWidth * fog.$3 / 2,
                      top: positions[fog.$1]!.dy - mapHeight * fog.$4 / 2,
                      width: mapWidth * fog.$3,
                      height: mapHeight * fog.$4,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: fog.$5,
                          child: Transform.rotate(
                            angle: fog.$6,
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) => RadialGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: .72),
                                  Colors.transparent,
                                ],
                                stops: const [0, .56, 1],
                              ).createShader(bounds),
                              child: Image.asset(
                                fog.$2,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                for (final dendrite in _dendriteAnchors)
                  Positioned(
                    left: mapWidth * dendrite.$2 - mapWidth * dendrite.$4 / 2,
                    top: mapHeight * dendrite.$3 - mapWidth * dendrite.$4 / 2,
                    width: mapWidth * dendrite.$4,
                    height: mapWidth * dendrite.$4,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: dendrite.$5,
                        child: Transform.rotate(
                          angle: dendrite.$6,
                          child: SvgPicture.asset(
                            dendrite.$1,
                            fit: BoxFit.contain,
                            clipBehavior: Clip.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                RepaintBoundary(
                  child: NeuroConnectionSvg(
                    width: mapWidth,
                    height: mapHeight,
                    nodes: nodes,
                    positions: positions,
                    completed: widget.completedNeurons,
                  ),
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
                        animate: _animating,
                        onTap: widget.onNodeTap,
                      ),
                    );
                  }),
              ]),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: const Color(0xB5FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x143C557C),
                  blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              const _BrandMark(),
              const SizedBox(width: 10),
              const Expanded(child: Text('Flooria',
                style: TextStyle(
                  color: neuroText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ))),
              _ProgressPill(
                value: '${widget.completedNeurons.length} / ${nodes.length}',
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: widget.onSettings,
                icon: const Icon(Icons.tune_rounded, color: neuroText),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),
            ]),
          ),
        ),
        Positioned(
          top: 61,
          left: 0,
          right: 0,
          child: NeuroNavigation(selected: 0, onTab: (tab) {
            switch (tab) {
              case 1: widget.onGames();
              case 2: widget.onAnalytics();
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
    required this.animate,
    required this.onTap,
  });

  final NeuronNode node;
  final NeuronAvailability state;
  final Animation<double> pulse;
  final bool animate;
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
    final size = node.id == 'node_01' && open ? 76.0
        : open ? 68.0 : complete ? 62.0 : 49.0;
    final color = complete
        ? const Color(0xFF53B99F)
        : const Color(0xFF716BE0);
    final lockedTints = <(Color, Color)>[
      (const Color(0xFFF1F4FA), const Color(0xFFD5DCEB)),
      (const Color(0xFFF0EFF9), const Color(0xFFD8D3ED)),
      (const Color(0xFFEEF7F4), const Color(0xFFD2E8E1)),
      (const Color(0xFFF8F3EF), const Color(0xFFEDDCD3)),
    ];
    final lockedTint = lockedTints[(node.slot - 1) % lockedTints.length];
    return Semantics(
      label: 'Node ${node.slot}, level ${node.level}, ${locked ? "locked" : complete ? "complete" : "open"}',
      button: !locked,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) => Transform.scale(
          scale: animate && open ? 1 + .018 * glow : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: locked ? null : () => onTap(node),
              child: AnimatedContainer(
                duration: animate ? const Duration(milliseconds: 260)
                    : Duration.zero,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: locked
                      ? RadialGradient(
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

                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A seamless pattern fixed to map-space. It pans and zooms with the nodes,
/// instead of stretching one bitmap across the full 2,450px world.
class _MapAtmosphere extends StatelessWidget {
  const _MapAtmosphere();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFF2F6FB),
          image: DecorationImage(
            image: AssetImage('assets/background/neural_hex_mesh.jpg'),
            fit: BoxFit.none,
            repeat: ImageRepeat.repeat,
            alignment: Alignment.topLeft,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x88F9FCFF),
              Color(0x9BF4F2FC),
              Color(0x8FFFF9F4),
            ],
          ),
        ),
      ),
    ],
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    height: 37,
    width: 37,
    decoration: BoxDecoration(
      color: const Color(0xFF7C84CC),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [],
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
      color: const Color(0xFFEFEFFA),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFE6E5F2)),
    ),
    child: Text(value, style: const TextStyle(
      color: Color(0xFF52628E), fontSize: 10,
      fontWeight: FontWeight.w900)),
  );
}
