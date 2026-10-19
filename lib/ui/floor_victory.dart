import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight celebratory result presentation shared by every mini-game.
enum VictoryAction { nextFloor, tower }

Future<VictoryAction> showFloorVictory(
  BuildContext context, {
  required int completedFloor,
  required String achievement,
  required String detail,
}) async {
  return await showGeneralDialog<VictoryAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Floor complete',
    barrierColor: const Color(0xFF211D3B).withValues(alpha: .64),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondary) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: Colors.transparent,
          child: _VictoryCard(
            completedFloor: completedFloor,
            achievement: achievement,
            detail: detail,
            onNext: () => Navigator.of(context).pop(VictoryAction.nextFloor),
            onTower: () => Navigator.of(context).pop(VictoryAction.tower),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .78, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  ) ?? VictoryAction.tower;
}

class _VictoryCard extends StatefulWidget {
  final int completedFloor;
  final String achievement;
  final String detail;
  final VoidCallback onNext;
  final VoidCallback onTower;
  const _VictoryCard({
    required this.completedFloor,
    required this.achievement,
    required this.detail,
    required this.onNext,
    required this.onTower,
  });
  @override
  State<_VictoryCard> createState() => _VictoryCardState();
}

class _VictoryCardState extends State<_VictoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController sparkle;
  @override
  void initState() {
    super.initState();
    sparkle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat();
  }
  @override
  void dispose() {
    sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE4A4), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x773C2A4D), blurRadius: 28, offset: Offset(0, 15)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 128, width: 205,
          child: AnimatedBuilder(
            animation: sparkle,
            builder: (context, _) => CustomPaint(
              painter: _VictorySparkles(sparkle.value),
              child: const Center(
                child: Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFAC40), size: 82),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text('FLOOR COMPLETE!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF43345B), fontSize: 25,
            fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 10),
        Text(widget.achievement,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF705C83),
            fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFD7F5E7),
            borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            const Icon(Icons.lock_open_rounded, color: Color(0xFF328C73), size: 28),
            const SizedBox(height: 6),
            Text('FLOOR ${widget.completedFloor + 1} UNLOCKED',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF326B5D),
                fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(widget.detail, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5A8378), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 21),
        SizedBox(
          width: double.infinity, height: 53,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB251),
              foregroundColor: const Color(0xFF483558),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
            onPressed: widget.onNext,
            icon: const Icon(Icons.arrow_upward_rounded),
            label: const Text('NEXT FLOOR',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: widget.onTower,
          child: const Text('Back to tower',
            style: TextStyle(color: Color(0xFF736483),
              fontWeight: FontWeight.w700))),
      ]),
    ),
  );
}

class _VictorySparkles extends CustomPainter {
  final double phase;
  const _VictorySparkles(this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const palette = [
      Color(0xFFFFA579), Color(0xFF8EDDC6),
      Color(0xFFB39AEF), Color(0xFFFFCF68),
    ];
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final breathe = math.sin(phase * 2 * math.pi + i) * 4;
      final r = 49 + (i % 4) * 12 + breathe;
      final pos = center + Offset(math.cos(a) * r, math.sin(a) * r);
      final paint = Paint()..color = palette[i % palette.length];
      if (i.isEven) {
        canvas.drawCircle(pos, 2.8 + (i % 3), paint);
      } else {
        final path = Path()
          ..moveTo(pos.dx, pos.dy - 5)
          ..lineTo(pos.dx + 3.5, pos.dy)
          ..lineTo(pos.dx, pos.dy + 5)
          ..lineTo(pos.dx - 3.5, pos.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _VictorySparkles other) => other.phase != phase;
}
