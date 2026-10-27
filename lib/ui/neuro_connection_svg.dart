import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/neuron_progression.dart';

/// Paints the graph with three reusable neuron-inspired SVG connection forms:
/// myelinated axons, branching dendrites, and vesicle-bearing synapses.
class NeuroConnectionSvg extends StatelessWidget {
  const NeuroConnectionSvg({
    super.key,
    required this.width,
    required this.height,
    required this.nodes,
    required this.positions,
    required this.completed,
  });

  final double width;
  final double height;
  final List<NeuronNode> nodes;
  final Map<String, Offset> positions;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        _buildSvg(),
        width: width,
        height: height,
        fit: BoxFit.fill,
      );

  String _buildSvg() {
    final byId = {for (final node in nodes) node.id: node};
    final defs = StringBuffer();
    final cellBodies = StringBuffer();
    final drawings = StringBuffer();
    var edgeIndex = 0;

    for (final node in nodes) {
      final center = positions[node.id];
      if (center != null) cellBodies.write(_cellMorphology(node, center));
    }

    for (final node in nodes) {
      for (final parentId in node.parents) {
        final parent = byId[parentId];
        final start = positions[parentId];
        final end = positions[node.id];
        if (parent == null || start == null || end == null) continue;

        final edge = _NeuralEdge.create(
          parent: parent,
          node: node,
          start: start,
          end: end,
          completed: completed,
        );
        defs.write(_gradient(edgeIndex, edge));
        drawings.write(_drawEdge(edgeIndex, edge, node.slot % 3));
        edgeIndex++;
      }
    }

    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${width.toStringAsFixed(0)}" '
        'height="${height.toStringAsFixed(0)}" '
        'viewBox="0 0 ${width.toStringAsFixed(0)} ${height.toStringAsFixed(0)}">'
        '<defs>$defs</defs>'
        '<g fill="none" stroke-linecap="round" stroke-linejoin="round">'
        '$cellBodies$drawings</g></svg>';
  }

  /// The game button is the cell body; these SVG arms make the map read as
  /// neurons rather than circles joined by wires.
  String _cellMorphology(NeuronNode node, Offset center) {
    final state = NeuronMapGraph.availability(node, completed);
    final radius = _NeuralEdge.radius(node, completed);
    final color = state == NeuronAvailability.complete
        ? '#45B89E'
        : state == NeuronAvailability.open
            ? '#8172E9'
            : const ['#7C9FCF', '#9386CC', '#65AB9F', '#D09178']
                [(node.slot - 1) % 4];
    final opacity = state == NeuronAvailability.locked ? '.52' : '.76';
    final body = StringBuffer()
      ..write('<circle cx="${_n(center.dx)}" cy="${_n(center.dy)}" '
          'r="${_n(radius + 4)}" fill="none" stroke="$color" '
          'stroke-width="1.6" stroke-opacity=".48"/>');

    const armAngles = [11.0, 82.0, 176.0, 281.0];
    const armLengths = [15.0, 23.0, 18.0, 25.0];
    for (var arm = 0; arm < armAngles.length; arm++) {
      final angle = (armAngles[arm] + node.slot * 9) * math.pi / 180;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-direction.dy, direction.dx);
      final base = center + direction * (radius + 3);
      final fork = center + direction * (radius + armLengths[arm]);
      final trunkControl = center + direction * (radius + armLengths[arm] * .58) +
          normal * (arm.isEven ? 2.2 : -1.6);
      final trunk = 'M${_n(base.dx)} ${_n(base.dy)} '
          'Q${_n(trunkControl.dx)} ${_n(trunkControl.dy)} '
          '${_n(fork.dx)} ${_n(fork.dy)}';
      body.write('<path d="$trunk" stroke="$color" stroke-width="2.5" '
          'stroke-opacity="$opacity"/>');

      for (final side in const [-1.0, 1.0]) {
        final twigLength = 8.0 + ((node.slot + arm) % 3) * 2.5;
        final branchSpread = 5.0 + ((node.slot + arm) % 2) * 3.0;
        final tip = fork + direction * twigLength + normal * (side * branchSpread);
        final control = fork + direction * (twigLength * .58) +
            normal * (side * branchSpread * .5);
        final twig = 'M${_n(fork.dx)} ${_n(fork.dy)} '
            'Q${_n(control.dx)} ${_n(control.dy)} '
            '${_n(tip.dx)} ${_n(tip.dy)}';
        body.write('<path d="$twig" stroke="$color" stroke-width="1.55" '
            'stroke-opacity="$opacity"/><circle cx="${_n(tip.dx)}" '
            'cy="${_n(tip.dy)}" r="1.8" fill="$color" '
            'fill-opacity="$opacity"/>');
      }
    }
    return body.toString();
  }

  String _gradient(int index, _NeuralEdge edge) =>
      '<linearGradient id="axon$index" gradientUnits="userSpaceOnUse" '
      'x1="${_n(edge.curve.start.dx)}" y1="${_n(edge.curve.start.dy)}" '
      'x2="${_n(edge.curve.end.dx)}" y2="${_n(edge.curve.end.dy)}">'
      '<stop offset="0" stop-color="${edge.colorA}"/>'
      '<stop offset="1" stop-color="${edge.colorB}"/>'
      '</linearGradient>';

  String _drawEdge(int index, _NeuralEdge edge, int motif) {
    final path = edge.curve.svgPath;
    final gradient = 'url(#axon$index)';
    final opacity = edge.active ? '.88' : '.58';
    final terminal = '<circle cx="${_n(edge.curve.end.dx)}" '
        'cy="${_n(edge.curve.end.dy)}" r="4.1" fill="$gradient" '
        'stroke="#FFFFFF" stroke-width="1.35" stroke-opacity=".96"/>';
    final sheath = '<path d="$path" stroke="$gradient" '
        'stroke-width="8" stroke-opacity="${edge.active ? '.15' : '.11'}"/>'
        '<path d="$path" stroke="$gradient" stroke-width="4.4" '
        'stroke-opacity="$opacity"/>'
        '<path d="$path" stroke="#FFFFFF" stroke-width="1.15" '
        'stroke-opacity="${edge.active ? '.66' : '.5'}"/>';

    switch (motif) {
      case 0:
        return '$sheath${_myelin(edge, gradient)}'
            '${_axonCollaterals(edge, gradient)}$terminal';
      case 1:
        return '$sheath${_dendriteForks(edge, gradient)}$terminal';
      default:
        return '${_synapticRelay(edge, gradient)}$terminal';
    }
  }

  String _myelin(_NeuralEdge edge, String gradient) {
    final beads = StringBuffer();
    for (final t in const [.18, .34, .50, .66, .82]) {
      final point = edge.curve.pointAt(t);
      final tangent = edge.curve.tangentAt(t);
      final angle = math.atan2(tangent.dy, tangent.dx) * 180 / math.pi;
      beads.write('<g transform="rotate(${_n(angle)} ${_n(point.dx)} ${_n(point.dy)})">'
          '<ellipse cx="${_n(point.dx)}" cy="${_n(point.dy)}" rx="5.4" ry="3.1" '
          'fill="$gradient" stroke="#FFFFFF" stroke-width="1.1" '
          'stroke-opacity=".92"/></g>');
    }
    return beads.toString();
  }

  String _axonCollaterals(_NeuralEdge edge, String gradient) {
    final branches = StringBuffer();
    for (final data in const [(0.38, -1.0), (0.63, 1.0)]) {
      final t = data.$1;
      final side = data.$2;
      final root = edge.curve.pointAt(t);
      final tangent = edge.curve.tangentAt(t);
      final normal = Offset(-tangent.dy, tangent.dx);
      final tip = root + normal * (side * 15) + tangent * 8;
      final control = root + normal * (side * 8) + tangent * 5;
      final branch = 'M${_n(root.dx)} ${_n(root.dy)} '
          'Q${_n(control.dx)} ${_n(control.dy)} ${_n(tip.dx)} ${_n(tip.dy)}';
      branches.write('<path d="$branch" stroke="$gradient" stroke-width="2.2" '
          'stroke-opacity=".78"/><circle cx="${_n(tip.dx)}" cy="${_n(tip.dy)}" '
          'r="2.1" fill="$gradient"/>');
    }
    return branches.toString();
  }

  String _dendriteForks(_NeuralEdge edge, String gradient) {
    final branches = StringBuffer();
    for (final data in const [(0.64, -1.0), (0.72, 1.0), (0.80, -1.0)]) {
      final t = data.$1;
      final side = data.$2;
      final root = edge.curve.pointAt(t);
      final tangent = edge.curve.tangentAt(t);
      final normal = Offset(-tangent.dy, tangent.dx);
      final length = 13.0 + (t * 7);
      final tip = root + normal * (side * length) + tangent * 5;
      final mid = root + normal * (side * length * .55) + tangent * 3;
      final branch = 'M${_n(root.dx)} ${_n(root.dy)} '
          'Q${_n(mid.dx)} ${_n(mid.dy)} ${_n(tip.dx)} ${_n(tip.dy)}';
      branches.write('<path d="$branch" stroke="$gradient" '
          'stroke-width="${_n(2.5 - t)}" stroke-opacity=".86"/>'
          '<circle cx="${_n(tip.dx)}" cy="${_n(tip.dy)}" r="2.4" '
          'fill="$gradient" stroke="#FFFFFF" stroke-width=".8"/>');
    }
    return branches.toString();
  }

  String _synapticRelay(_NeuralEdge edge, String gradient) {
    final pre = edge.curve.pointAt(.45);
    final post = edge.curve.pointAt(.56);
    final preTangent = edge.curve.tangentAt(.45);
    final prePath = edge.curve.segment(0, .45);
    final postPath = edge.curve.segment(.56, 1);
    final normal = Offset(-preTangent.dy, preTangent.dx);
    final vesicles = StringBuffer();
    for (final data in const [(-3.5, -2.2), (0.0, 2.8), (3.5, -1.8)]) {
      final center = Offset.lerp(pre, post, .5)! +
          normal * data.$1 + preTangent * data.$2;
      vesicles.write('<circle cx="${_n(center.dx)}" cy="${_n(center.dy)}" '
          'r="2.5" fill="$gradient" stroke="#FFFFFF" stroke-width="1"/>');
    }

    return '<path d="$prePath" stroke="$gradient" stroke-width="8" '
        'stroke-opacity=".14"/><path d="$prePath" stroke="$gradient" '
        'stroke-width="4.3" stroke-opacity="${edge.active ? '.88' : '.58'}"/>'
        '<path d="$prePath" stroke="#FFFFFF" stroke-width="1.1" '
        'stroke-opacity=".66"/>'
        '<path d="$postPath" stroke="$gradient" stroke-width="8" '
        'stroke-opacity=".14"/><path d="$postPath" stroke="$gradient" '
        'stroke-width="4.3" stroke-opacity="${edge.active ? '.88' : '.58'}"/>'
        '<path d="$postPath" stroke="#FFFFFF" stroke-width="1.1" '
        'stroke-opacity=".66"/>'
        '<circle cx="${_n(pre.dx)}" cy="${_n(pre.dy)}" r="4.8" '
        'fill="$gradient" stroke="#FFFFFF" stroke-width="1.2"/>'
        '<circle cx="${_n(post.dx)}" cy="${_n(post.dy)}" r="4.8" '
        'fill="$gradient" stroke="#FFFFFF" stroke-width="1.2"/>'
        '$vesicles';
  }

  static String _n(double value) => value.toStringAsFixed(1);
}

/// Shared curve geometry keeps the visible SVG and moving signal beads aligned.
class _NeuralEdge {
  const _NeuralEdge({
    required this.curve,
    required this.active,
    required this.colorA,
    required this.colorB,
  });

  final _NeuralCurve curve;
  final bool active;
  final String colorA;
  final String colorB;

  factory _NeuralEdge.create({
    required NeuronNode parent,
    required NeuronNode node,
    required Offset start,
    required Offset end,
    required Set<String> completed,
  }) {
    final vector = end - start;
    final distance = vector.distance;
    final direction = vector / distance;
    final startRadius = radius(parent, completed) + 5;
    final endRadius = radius(node, completed) + 5;
    final from = start + direction * startRadius;
    final to = end - direction * endRadius;
    final normal = Offset(-direction.dy, direction.dx);
    final sign = (parent.slot + node.slot).isEven ? 1.0 : -1.0;
    final bend = math.min(36.0, distance * .16) * sign;
    final c1 = from + vector * .34 + normal * bend;
    final c2 = from + vector * .68 + normal * bend * 1.15;

    final passed = completed.contains(parent.id) && completed.contains(node.id);
    final nextOpen = completed.contains(parent.id) &&
        NeuronMapGraph.availability(node, completed) == NeuronAvailability.open;
    final currentEdge = NeuronMapGraph.availability(parent, completed) ==
            NeuronAvailability.open &&
        NeuronMapGraph.availability(node, completed) == NeuronAvailability.locked;
    final active = passed || nextOpen || currentEdge;
    final colorA = passed
        ? '#51C3A2'
        : active
            ? '#A793FF'
            : '#8299BD';
    final colorB = passed
        ? '#6ED6C0'
        : active
            ? '#5FBDEB'
            : '#A2B4D1';

    return _NeuralEdge(
      curve: _NeuralCurve(from, c1, c2, to),
      active: active,
      colorA: colorA,
      colorB: colorB,
    );
  }

  static double radius(NeuronNode node, Set<String> completed) {
    final state = NeuronMapGraph.availability(node, completed);
    if (state == NeuronAvailability.open) return node.id == 'node_01' ? 38 : 34;
    if (state == NeuronAvailability.complete) return 33;
    return 27;
  }
}

class _NeuralCurve {
  const _NeuralCurve(this.start, this.control1, this.control2, this.end);

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  String get svgPath => 'M${_n(start.dx)} ${_n(start.dy)} '
      'C${_n(control1.dx)} ${_n(control1.dy)} '
      '${_n(control2.dx)} ${_n(control2.dy)} '
      '${_n(end.dx)} ${_n(end.dy)}';

  Offset pointAt(double t) {
    final u = 1 - t;
    return start * (u * u * u) + control1 * (3 * u * u * t) +
        control2 * (3 * u * t * t) + end * (t * t * t);
  }

  Offset tangentAt(double t) {
    final u = 1 - t;
    final tangent = (control1 - start) * (3 * u * u) +
        (control2 - control1) * (6 * u * t) +
        (end - control2) * (3 * t * t);
    return tangent / tangent.distance;
  }

  String segment(double from, double to) {
    // Sampling the same cubic produces smooth endpoints for the short synapse gap.
    final steps = math.max(4, ((to - from) * 24).round()).toInt();
    final points = List.generate(steps + 1, (index) {
      return pointAt(from + (to - from) * index / steps);
    });
    return 'M${_n(points.first.dx)} ${_n(points.first.dy)} '
        'L${points.skip(1).map((p) => '${_n(p.dx)} ${_n(p.dy)}').join(' ')}';
  }

  static String _n(double value) => value.toStringAsFixed(1);
}

/// Moves signal beads along the same biological curves rendered by the SVG.
class NeuroFlowParticles extends CustomPainter {
  const NeuroFlowParticles({
    required this.nodes,
    required this.positions,
    required this.completed,
    required this.phase,
  });

  final List<NeuronNode> nodes;
  final Map<String, Offset> positions;
  final Set<String> completed;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final node in nodes) node.id: node};
    for (final node in nodes) {
      for (final parentId in node.parents) {
        final parent = byId[parentId];
        final start = positions[parentId];
        final end = positions[node.id];
        if (parent == null || start == null || end == null) continue;
        final edge = _NeuralEdge.create(
          parent: parent,
          node: node,
          start: start,
          end: end,
          completed: completed,
        );
        if (!edge.active) continue;

        final path = Path()
          ..moveTo(edge.curve.start.dx, edge.curve.start.dy)
          ..cubicTo(
            edge.curve.control1.dx,
            edge.curve.control1.dy,
            edge.curve.control2.dx,
            edge.curve.control2.dy,
            edge.curve.end.dx,
            edge.curve.end.dy,
          );
        final metric = path.computeMetrics().first;
        final progress = (phase + node.slot * .113) % 1;
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent == null) continue;
        final tint = node.slot.isEven
            ? const Color(0xFF9C8AFF)
            : const Color(0xFF68C8EE);
        canvas.drawCircle(
          tangent.position,
          8,
          Paint()..color = tint.withValues(alpha: .24),
        );
        canvas.drawCircle(
          tangent.position,
          3.2,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeuroFlowParticles oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.completed.length != completed.length ||
      !oldDelegate.completed.containsAll(completed) ||
      !completed.containsAll(oldDelegate.completed);
}
