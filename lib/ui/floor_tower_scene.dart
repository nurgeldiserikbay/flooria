import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/floor_engine.dart';

/// An illustrated-looking floor stack built from actual interactive,
/// scalable geometry rather than a castle image or baked-in floor numbers.
class FloorTowerScene extends StatelessWidget {
  final int currentFloor;
  final ValueChanged<int> onFloorTap;
  const FloorTowerScene({
    super.key, required this.currentFloor, required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = currentFloor + 3;
    final bottom = math.max(1, currentFloor - 2);
    final floors = [
      for (int f = top; f >= bottom; f--) f,
    ];
    return LayoutBuilder(builder: (context, c) {
      final blockHeight = math.min(105.0, c.maxHeight / floors.length);
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in floors)
            SizedBox(
              height: blockHeight,
              child: _TowerBlock(
                floor: f,
                current: currentFloor,
                onTap: () => onFloorTap(f),
              ),
            ),
        ],
      ));
    });
  }
}

class _TowerBlock extends StatelessWidget {
  final int floor;
  final int current;
  final VoidCallback onTap;
  const _TowerBlock({
    required this.floor, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = floor == current;
    final passed = floor < current;
    final name = const FloorEngine().challengeFor(floor).gameId
      == 'merge2048' ? '2048' : 'Number Trail';
    final image = name == '2048'
      ? 'assets/art/fantasy_garden_puzzle_game_ui.webp'
      : 'assets/art/glowing_puzzle_crown_pedestal.webp';
    return LayoutBuilder(builder: (context, c) {
      final width = math.min(c.maxWidth * .94, active ? 335.0 : 296.0);
      final shift = math.sin(floor * 1.7) * (active ? 0 : 11);
      final height = c.maxHeight * .96;
      return Center(child: Transform.translate(
        offset: Offset(shift, 0),
        child: SizedBox(
          width: width, height: height,
          child: Semantics(
            label: 'Floor $floor, $name, ${passed ? "completed" : active ? "current" : "locked"}',
            button: true,
            child: GestureDetector(
              onTap: onTap,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(
                  active
                    ? 'assets/art/floor_current.webp'
                    : passed
                      ? 'assets/art/floor_completed.webp'
                      : 'assets/art/floor_locked.webp',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => CustomPaint(
                    painter: _FloorBlockPainter(
                      active: active, passed: passed,
                    ),
                  ),
                )),
                Positioned(
                  top: height * .24, left: width * .10,
                  right: width * .11, bottom: height * .22,
                  child: Row(children: [
                    SizedBox(
                      width: width * .18,
                      child: Center(child: Text('$floor',
                        style: TextStyle(
                          fontSize: active ? 23 : 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFEAC0),
                          shadows: const [Shadow(
                            color: Color(0xFF493039),
                            blurRadius: 3,
                            offset: Offset(1, 2))],
                        ),
                      )),
                    ),
                    SizedBox(width: width * .025),
                    Expanded(child: Row(children: [
                      SizedBox(
                        width: math.min(33.0, height * .44),
                        height: math.min(33.0, height * .44),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(image, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFFFF4D8),
                          fontSize: active ? 13 : 12,
                          fontWeight: FontWeight.w900,
                          shadows: const [Shadow(
                            color: Color(0xFF382A35), blurRadius: 4)],
                        ),
                      )),
                    ])),
                    SizedBox(
                      width: width * .18,
                      child: Icon(
                        passed ? Icons.check_circle_rounded
                          : active ? Icons.play_circle_fill_rounded
                          : Icons.lock_rounded,
                        size: active ? 24 : 21,
                        color: active
                          ? const Color(0xFFFFE8A0)
                          : passed
                            ? const Color(0xFFB8FFD1)
                            : const Color(0xFFE4DCEB),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ));
    });
  }
}

class _FloorBlockPainter extends CustomPainter {
  final bool active;
  final bool passed;
  const _FloorBlockPainter({required this.active, required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadow = Paint()
      ..color = const Color(0x553E3867)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final body = Path()
      ..moveTo(w * .04, h * .22)
      ..lineTo(w * .94, h * .22)
      ..lineTo(w * .99, h * .37)
      ..lineTo(w * .99, h * .82)
      ..lineTo(w * .91, h * .94)
      ..lineTo(w * .07, h * .94)
      ..lineTo(w * .01, h * .79)
      ..lineTo(w * .01, h * .36)
      ..close();
    canvas.drawPath(body.shift(const Offset(0, 5)), shadow);
    canvas.drawPath(body, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: active
          ? [const Color(0xFFFFEFAA), const Color(0xFFE9A94D),
             const Color(0xFFAC633A)]
          : passed
          ? [const Color(0xFFDBF0D7), const Color(0xFFAFCCAA),
             const Color(0xFF7F9B83)]
          : [const Color(0xFFE9E2D9), const Color(0xFFBEAFB4),
             const Color(0xFF8F8197)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));
    final side = Path()
      ..moveTo(w * .07, h * .76)
      ..lineTo(w * .92, h * .76)
      ..lineTo(w * .99, h * .82)
      ..lineTo(w * .91, h * .94)
      ..lineTo(w * .07, h * .94)
      ..lineTo(w * .01, h * .79)
      ..close();
    canvas.drawPath(side, Paint()
      ..color = active ? const Color(0xFF95563B)
        : passed ? const Color(0xFF709382)
        : const Color(0xFF847D92));
    final surface = Path()
      ..moveTo(w * .07, h * .05)
      ..lineTo(w * .91, h * .05)
      ..lineTo(w * .98, h * .22)
      ..lineTo(w * .93, h * .31)
      ..lineTo(w * .06, h * .31)
      ..lineTo(w * .015, h * .22)
      ..close();
    canvas.drawPath(surface, Paint()
      ..color = active ? const Color(0xFFFFF0C3)
        : passed ? const Color(0xFFE5F1D9)
        : const Color(0xFFF4EDE7));
    final front = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * .045, h * .27, w * .955, h * .78),
      Radius.circular(h * .15));
    canvas.drawRRect(front, Paint()
      ..color = active ? const Color(0xFFFFE2A4)
        : passed ? const Color(0xFFE0EDD3)
        : const Color(0xFFE2D9DB));
    canvas.drawRRect(front, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 3 : 2
      ..color = active ? const Color(0xFFFFC35E)
        : const Color(0xFFC6AE9E));
    canvas.drawLine(Offset(w * .085, h * .35),
      Offset(w * .915, h * .35),
      Paint()..color = const Color(0x99FFFFFF)..strokeWidth = 1.7);
    if (active) {
      final sparkle = Paint()..color = const Color(0xFFFFF8C4);
      for (final dx in [.07, .93]) {
        final center = Offset(w * dx, h * .24);
        canvas.drawCircle(center, 3.4, sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloorBlockPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.passed != passed;
}
