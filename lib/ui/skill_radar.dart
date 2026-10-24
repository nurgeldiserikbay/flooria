import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/player_stats.dart';

/// Lightweight Dota-style stat polygon. No image or chart dependency.
/// The empty axes are not rated or silently invented.
class SkillRadarChart extends StatelessWidget {
  const SkillRadarChart({super.key, required this.ratings});
  final List<GameSkillRating> ratings;

  @override
  Widget build(BuildContext context) {
    final summary = ratings.map((r) =>
        '${r.name}: ${r.value == null ? 'not measured' : '${r.value} of 100'}')
      .join(', ');
    return Semantics(
      label: 'Game skill radar. $summary',
      image: true,
      child: SizedBox(
        height: 264,
        width: double.infinity,
        child: CustomPaint(
          painter: _SkillRadarPainter(ratings),
        ),
      ),
    );
  }
}

class _SkillRadarPainter extends CustomPainter {
  const _SkillRadarPainter(this.ratings);
  final List<GameSkillRating> ratings;

  static const ink = Color(0xFFE1EBFF);
  static const line = Color(0xFF3F568E);
  static const fill = Color(0x665E75FE);
  static const outline = Color(0xFF8CE9FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.length != 6) return;
    final center = Offset(size.width / 2, size.height / 2 + 1);
    final radius = math.min(size.width * .265, size.height * .285);
    final angles = List<double>.generate(
      6, (index) => -math.pi / 2 + math.pi * 2 * index / 6,
    );
    Offset point(double angle, double distance) =>
        Offset(center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance);

    // Spider-web grid, with neutral lines and four step rings.
    for (var ring = 1; ring <= 4; ring++) {
      final polygon = Path();
      for (var i = 0; i < 6; i++) {
        final pos = point(angles[i], radius * ring / 4);
        if (i == 0) {
          polygon.moveTo(pos.dx, pos.dy);
        } else {
          polygon.lineTo(pos.dx, pos.dy);
        }
      }
      polygon.close();
      canvas.drawPath(polygon, Paint()
        ..color = ring == 4 ? const Color(0xFF7A88C7) : line
        ..strokeWidth = ring == 4 ? 1.7 : 1.0
        ..style = PaintingStyle.stroke);
    }
    for (final angle in angles) {
      canvas.drawLine(center, point(angle, radius),
        Paint()..color = line..strokeWidth = 1.3);
    }

    final known = ratings.where((r) => r.value != null).length;
    if (known > 0) {
      final shape = Path();
      for (var i = 0; i < 6; i++) {
        final value = ratings[i].value;
        final distance = value == null ? 0.0
          : radius * (value.clamp(0, 100) / 100);
        final p = point(angles[i], distance);
        if (i == 0) {
          shape.moveTo(p.dx, p.dy);
        } else {
          shape.lineTo(p.dx, p.dy);
        }
      }
      shape.close();
      if (known >= 3) {
        canvas.drawPath(shape, Paint()..color = fill);
      }
      canvas.drawPath(shape, Paint()
        ..color = outline..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round);

      for (var i = 0; i < 6; i++) {
        final rating = ratings[i];
        if (rating.value == null) continue;
        final p = point(angles[i], radius * rating.value! / 100);
        canvas.drawCircle(p, 5.1,
          Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(p, 3.5,
          Paint()..color = outline);
      }
    }

    // Deliberately place textual labels outside the graph, not on the art.
    for (var i = 0; i < 6; i++) {
      final rating = ratings[i];
      final labelPosition = point(angles[i], radius + 41);
      final value = rating.value == null ? '—' : '${rating.value}';
      final labelPainter = TextPainter(
        textAlign: TextAlign.center,
        maxLines: 2,
        textDirection: TextDirection.ltr,
        text: TextSpan(children: [
          TextSpan(text: '${rating.name}\n',
            style: const TextStyle(fontSize: 12.5,
              height: 1.15, color: ink,
              fontWeight: FontWeight.w800)),
          TextSpan(text: value,
            style: TextStyle(fontSize: 12.5, height: 1.15,
              color: rating.value == null
                ? const Color(0xFF99A8D0) : outline,
              fontWeight: FontWeight.w900)),
        ]),
      )..layout(maxWidth: 90);
      final x = math.max(2.0, math.min(
        size.width - labelPainter.width - 2,
        labelPosition.dx - labelPainter.width / 2));
      final y = math.max(2.0, math.min(
        size.height - labelPainter.height - 2,
        labelPosition.dy - labelPainter.height / 2));
      labelPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _SkillRadarPainter old) {
    if (ratings.length != old.ratings.length) return true;
    for (var i = 0; i < ratings.length; i++) {
      if (ratings[i].value != old.ratings[i].value) return true;
    }
    return false;
  }
}
