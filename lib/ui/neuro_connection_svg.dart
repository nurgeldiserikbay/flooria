import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/neuron_progression.dart';

/// Draws the branching network as one lightweight SVG picture.
///
/// Three reusable edge motifs are mixed through the graph: a travelling signal,
/// a dendrite fork, and a paired conduction trace. Flutter supplies the phase
/// so the paths stay vector based without SVG-side timers or JavaScript.
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
    final edges = StringBuffer();
    for (final node in nodes) {
      for (final parentId in node.parents) {
        final parent = byId[parentId];
        final start = positions[parentId];
        final end = positions[node.id];
        if (parent == null || start == null || end == null) continue;
        edges.write(_edgeSvg(parent, node, start, end));
      }
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${width.toStringAsFixed(0)}" '
        'height="${height.toStringAsFixed(0)}" '
        'viewBox="0 0 ${width.toStringAsFixed(0)} ${height.toStringAsFixed(0)}">'
        '<g fill="none" stroke-linecap="round" stroke-linejoin="round">'
        '$edges</g></svg>';
  }

  String _edgeSvg(NeuronNode parent, NeuronNode node, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final sideBend = dx * .14;
    final c1 = Offset(start.dx + sideBend, start.dy + dy * .38);
    final c2 = Offset(end.dx - sideBend, end.dy - dy * .38);
    final path = 'M${_n(start.dx)} ${_n(start.dy)} '
        'C${_n(c1.dx)} ${_n(c1.dy)} ${_n(c2.dx)} ${_n(c2.dy)} '
        '${_n(end.dx)} ${_n(end.dy)}';

    final passed = completed.contains(parent.id) && completed.contains(node.id);
    final canAdvance = completed.contains(parent.id) &&
        NeuronMapGraph.availability(node, completed) == NeuronAvailability.open;
    final currentBranch = NeuronMapGraph.availability(parent, completed) ==
            NeuronAvailability.open &&
        NeuronMapGraph.availability(node, completed) == NeuronAvailability.locked;
    final active = passed || canAdvance || currentBranch;
    final color = passed
        ? '#55B69D'
        : canAdvance || currentBranch
            ? node.slot.isEven ? '#8B7CE2' : '#62A9D4'
            : '#7B8EAE';
    final opacity = passed ? '.84' : canAdvance ? '.84' : currentBranch ? '.62' : '.30';
    final base = '<path d="$path" stroke="$color" stroke-width="${active ? 2.8 : 2.1}" '
        'stroke-opacity="$opacity"/>';

    switch (node.slot % 3) {
      case 0:
        return '$base'
            '<path d="$path" stroke="$color" stroke-width="${passed ? 2.5 : 2.0}" '
            'stroke-opacity="${active ? '.96' : '.44'}" '
            'stroke-dasharray="1.5 10"/>';
      case 1:
        final midpoint = _cubicPoint(start, c1, c2, end, .52);
        final spread = dx >= 0 ? 1 : -1;
        final forkA = 'M${_n(midpoint.dx)} ${_n(midpoint.dy)} '
            'Q${_n(midpoint.dx + spread * 13)} ${_n(midpoint.dy - 2)} '
            '${_n(midpoint.dx + spread * 18)} ${_n(midpoint.dy - 13)}';
        final forkB = 'M${_n(midpoint.dx)} ${_n(midpoint.dy)} '
            'Q${_n(midpoint.dx - spread * 12)} ${_n(midpoint.dy + 5)} '
            '${_n(midpoint.dx - spread * 17)} ${_n(midpoint.dy + 15)}';
        return '$base'
            '<path d="$path" stroke="$color" stroke-width="1.8" '
            'stroke-opacity="${active ? '.86' : '.38'}" '
            'stroke-dasharray="2 9"/>'
            '<path d="$forkA" stroke="$color" stroke-width="1.35" '
            'stroke-opacity="${active ? '.72' : '.32'}"/>'
            '<path d="$forkB" stroke="$color" stroke-width="1.15" '
            'stroke-opacity="${active ? '.62' : '.27'}"/>';
      default:
        final length = math.sqrt(dx * dx + dy * dy);
        final nx = length == 0 ? 0.0 : -dy / length * 4.0;
        final ny = length == 0 ? 0.0 : dx / length * 4.0;
        final paired = 'M${_n(start.dx + nx)} ${_n(start.dy + ny)} '
            'C${_n(c1.dx + nx)} ${_n(c1.dy + ny)} '
            '${_n(c2.dx + nx)} ${_n(c2.dy + ny)} '
            '${_n(end.dx + nx)} ${_n(end.dy + ny)}';
        return '$base'
            '<path d="$paired" stroke="$color" stroke-width="1.15" '
            'stroke-opacity="${active ? '.68' : '.31'}" '
            'stroke-dasharray="2 8"/>';
    }
  }

  static Offset _cubicPoint(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return Offset(
      u * u * u * a.dx + 3 * u * u * t * b.dx +
          3 * u * t * t * c.dx + t * t * t * d.dx,
      u * u * u * a.dy + 3 * u * u * t * b.dy +
          3 * u * t * t * c.dy + t * t * t * d.dy,
    );
  }

  static String _n(double value) => value.toStringAsFixed(1);
}

/// Animates signal beads over the static SVG motifs without reparsing the SVG
/// on every frame. Only edges touching the current or next open neuron flow.
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
        final touchesCurrent = NeuronMapGraph.availability(parent, completed) ==
            NeuronAvailability.open;
        final opensNext = completed.contains(parent.id) &&
            NeuronMapGraph.availability(node, completed) == NeuronAvailability.open;
        if (!touchesCurrent && !opensNext) continue;

        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final bend = dx * .14;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(start.dx + bend, start.dy + dy * .38,
              end.dx - bend, end.dy - dy * .38, end.dx, end.dy);
        final metric = path.computeMetrics().first;
        final progress = (phase + node.slot * .113) % 1;
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent == null) continue;
        final tint = node.slot.isEven
            ? const Color(0xFF8B7CE2)
            : const Color(0xFF62A9D4);
        canvas.drawCircle(tangent.position, 7,
          Paint()..color = tint.withValues(alpha: .2));
        canvas.drawCircle(tangent.position, 2.5,
          Paint()..color = Colors.white);
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
