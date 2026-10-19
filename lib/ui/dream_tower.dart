import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight illustration made entirely from vector geometry.
class DreamTower extends StatefulWidget {
  const DreamTower({super.key});
  @override
  State<DreamTower> createState() => _DreamTowerState();
}

class _DreamTowerState extends State<DreamTower>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion;
  @override
  void initState() {
    super.initState();
    motion = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    builder: (context, _) => CustomPaint(
      painter: DreamTowerPainter(motion.value),
      size: const Size(double.infinity, 270),
    ),
  );
}

class DreamTowerPainter extends CustomPainter {
  final double phase;
  const DreamTowerPainter(this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Fill the stage first, then uniformly scale the tower artwork.
    // Independent X/Y scaling made the tower unnaturally tall on phones.
    final background = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF8BD8FA), Color(0xFFD2F3FF), Color(0xFFF5F2D8)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), background);
    final scale = math.min(w / 300, h * .70 / 275);
    canvas.save();
    canvas.translate(w / 2 - 170 * scale, h * .11);
    canvas.scale(scale);
    _circle(canvas, 269, 46, 34, const Color(0xFFFFE29C));
    _circle(canvas, 269, 46, 44, const Color(0xFFFFFBEF).withValues(alpha: .38));
    for (final star in const [(48.0, 48.0, 2.0), (86.0, 84.0, 2.0), (245.0, 101.0, 2.0), (297.0, 118.0, 3.0), (226.0, 34.0, 2.0)]) {
      _circle(canvas, star.$1, star.$2 + math.sin(phase * math.pi * 2 + star.$1) * 2, star.$3, Colors.white);
    }
    _cloud(canvas, 48, 217 + phase * 5, 1.05, const Color(0xFFF7FCFF));
    _cloud(canvas, 296, 223 - phase * 4, 1.22, const Color(0xFFE9F8FF));
    _cloud(canvas, 57, 120, .68, Colors.white.withValues(alpha: .52));
    _cloud(canvas, 294, 138, .63, Colors.white.withValues(alpha: .5));

    final shadow = Paint()..color = const Color(0xFFBFC4E6).withValues(alpha: .25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(const Rect.fromLTWH(91, 250, 162, 17), shadow);

    // Floating island and six gently separated architectural levels.
    _poly(canvas, [const Offset(70, 244), const Offset(170, 266), const Offset(269, 244), const Offset(170, 225)], const Color(0xFF9BE28A));
    _poly(canvas, [const Offset(70, 244), const Offset(170, 266), const Offset(170, 274), const Offset(70, 252)], const Color(0xFF65AF88));
    _poly(canvas, [const Offset(170, 266), const Offset(269, 244), const Offset(269, 252), const Offset(170, 274)], const Color(0xFF498F8E));
    const fronts = [
      Color(0xFFFFE3B5), Color(0xFFFFC6A6), Color(0xFFE8CCFF),
      Color(0xFFAFF0D4), Color(0xFFFFDEA1),
    ];
    const sides = [
      Color(0xFFD5A4A5), Color(0xFFE59E8A), Color(0xFFA99BDA),
      Color(0xFF79BFBF), Color(0xFFCDA8A2),
    ];
    const roofs = [
      Color(0xFFFFA987), Color(0xFFFFD17E), Color(0xFF9E91ED),
      Color(0xFF60C9B4), Color(0xFFF59CBE),
    ];
    for (var i = 0; i < 5; i++) {
      final y = 222.0 - i * 31;
      final left = i.isEven ? 100.0 : 106.0;
      final right = 240.0 - (i.isEven ? 0 : 6);
      _poly(canvas, [Offset(left, y), Offset(170, y + 14), Offset(170, y - 18), Offset(left, y - 33)], fronts[i]);
      _poly(canvas, [Offset(170, y + 14), Offset(right, y), Offset(right, y - 33), Offset(170, y - 18)], sides[i]);
      _poly(canvas, [Offset(left - 9, y - 33), Offset(170, y - 15), Offset(right + 9, y - 33), Offset(170, y - 53)], roofs[i]);
      _poly(canvas, [Offset(left - 9, y - 33), Offset(170, y - 15), Offset(170, y - 9), Offset(left - 9, y - 27)], Color.lerp(roofs[i], const Color(0xFF6D508C), .22)!);
      _poly(canvas, [Offset(170, y - 15), Offset(right + 9, y - 33), Offset(right + 9, y - 27), Offset(170, y - 9)], Color.lerp(roofs[i], const Color(0xFF403A76), .34)!);
      for (var j = 0; j < 2; j++) {
        final wx = left + 24 + j * 37;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, y - 23, 14, 22), const Radius.circular(7)), Paint()..color = i == 2 ? const Color(0xFFFFF1A3) : const Color(0xFF86BFE5));
        _line(canvas, Offset(wx + 7, y - 23), Offset(wx + 7, y - 1), const Color(0xFFF8F3FE), 1.4);
      }
    }
    // Tower crown.
    _poly(canvas, [const Offset(121, 63), const Offset(170, 12), const Offset(219, 63), const Offset(170, 83)], const Color(0xFFF8C4E0));
    _poly(canvas, [const Offset(121, 63), const Offset(170, 83), const Offset(170, 100), const Offset(121, 80)], const Color(0xFFE89DCB));
    _poly(canvas, [const Offset(170, 83), const Offset(219, 63), const Offset(219, 80), const Offset(170, 100)], const Color(0xFFB889C6));
    _line(canvas, const Offset(170, 11), const Offset(170, 0), const Color(0xFFDCB875), 3);
    _circle(canvas, 170, 3, 4, const Color(0xFFEBCB8D));
    // Playful flags and a golden doorway make the miniature tower read as a
    // game destination rather than a diagram. Everything remains vector based.
    _poly(canvas, [
      const Offset(172, 4), const Offset(199, 12),
      const Offset(172, 22),
    ], const Color(0xFFFF8B73));
    final door = Paint()..color = const Color(0xFFFFD16D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(157, 187, 23, 37),
        const Radius.circular(11)), door);
    _circle(canvas, 173, 205, 2.5, const Color(0xFFFFFCDB));
    _cloud(canvas, 38, 251, .88, const Color(0xFFFFFFFF));
    _cloud(canvas, 294, 259, 1.05, const Color(0xFFFFFFFF));
    canvas.restore();
  }

  void _circle(Canvas c, double x, double y, double r, Color color) {
    c.drawCircle(Offset(x, y), r, Paint()..color = color);
  }

  void _line(Canvas c, Offset a, Offset b, Color color, double width) {
    c.drawLine(a, b, Paint()..color=color..strokeWidth=width..strokeCap=StrokeCap.round);
  }

  void _poly(Canvas c, List<Offset> points, Color color) {
    final path=Path()..moveTo(points.first.dx,points.first.dy);
    for(final p in points.skip(1)){path.lineTo(p.dx,p.dy);}
    path.close();
    c.drawPath(path,Paint()..color=color);
  }

  void _cloud(Canvas c, double x, double y, double scale, Color color) {
    final paint=Paint()..color=color;
    c.save();
    c.translate(x,y);
    c.scale(scale);
    c.drawOval(const Rect.fromLTWH(-42,-9,84,25),paint);
    c.drawCircle(const Offset(-17,-7),18,paint);
    c.drawCircle(const Offset(8,-15),23,paint);
    c.drawCircle(const Offset(27,-5),15,paint);
    c.restore();
  }
  @override
  bool shouldRepaint(covariant DreamTowerPainter oldDelegate) => phase != oldDelegate.phase;
}
