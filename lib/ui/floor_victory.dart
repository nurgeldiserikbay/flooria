import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fantasy_ui.dart';

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
    barrierLabel: 'Neuron complete',
    barrierColor: const Color(0xFF101A3E).withValues(alpha: .43),
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
    child: FantasyPanel(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 108, width: 195,
          child: AnimatedBuilder(
            animation: sparkle,
            builder: (context, _) => CustomPaint(
              painter: _VictorySparkles(sparkle.value),
              child: Center(child: Container(
                width: 93, height: 93,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF92F0FF), Color(0xFF8575FF)]),
                  border: Border.all(color: Colors.white, width: 4),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(
                    color: Color(0x44D5A04B), blurRadius: 18,
                    offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFF284181), size: 51),
              )),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('NEURON COMPLETE!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFFFFFFF),
            fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        Text(widget.achievement,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB9D2F7),
            fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF294F85),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFFFFFFF), width: 2)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_open_rounded,
              color: Color(0xFF8DEBFF), size: 24),
            const SizedBox(width: 10),
            Flexible(child: Text('Neuron ${widget.completedFloor + 1} unlocked',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900,
                fontSize: 15))),
          ]),
        ),
        const SizedBox(height: 8),
        Text(widget.detail, textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB5C9EC), fontSize: 12)),
        const SizedBox(height: 22),
        FantasyButton(
          label: 'NEXT NEURON',
          icon: Icons.arrow_upward_rounded,
          onPressed: widget.onNext,
        ),
        const SizedBox(height: 11),
        TextButton(onPressed: widget.onTower,
          child: const Text('Back to map',
            style: TextStyle(color: Color(0xFF9CDDF7),
              fontWeight: FontWeight.w800))),
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
