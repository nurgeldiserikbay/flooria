import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/floor_engine.dart';

/// Five rendered floors are a moving window into the infinite tower.
/// One common architectural shaft and overlapping cornices make it read
/// as a single building rather than five unrelated game cards.
class FloorTowerScene extends StatelessWidget {
  final int currentFloor;
  final ValueChanged<int> onFloorTap;
  const FloorTowerScene({
    super.key,
    required this.currentFloor,
    required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final first = math.max(1, currentFloor - 2);
    final highest = first + 4;
    final floors = List<int>.generate(5, (i) => highest - i);
    final stageHeight = box.maxHeight;
    final step = stageHeight / 5.05;
    // All levels retain the original sprite's width/height relationship.
    // Their cornices overlap, but the actual image is never stretched.
    final spriteWidth = math.min(box.maxWidth, 385.0);
    final spriteHeight = math.min(spriteWidth / 2.77, step * 1.48);
    final towerWidth = math.min(spriteWidth * .76, box.maxWidth * .77);

    return ClipRect(child: Stack(children: [
      // Continuous stone walls underneath every ledge. This is essential
      // to avoid the disjointed floating-card appearance.
      Positioned(
        top: -12, bottom: -18,
        left: (box.maxWidth - towerWidth) / 2,
        width: towerWidth,
        child: const CustomPaint(painter: _TowerShaftPainter()),
      ),
      for (var i = 0; i < floors.length; i++)
        Positioned(
          top: i * step - spriteHeight * .18,
          left: 0, right: 0,
          height: spriteHeight,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              // Distant floors are subtly narrower: architectural depth,
              // not a dramatic skew that makes their labels unreadable.
              width: spriteWidth * (1 - i * .018),
              height: spriteHeight,
              child: _ArchitecturalFloor(
                floor: floors[i],
                current: currentFloor,
                onTap: () => onFloorTap(floors[i]),
              ),
            ),
          ),
        ),
      // Atmospheric fade makes the tower visibly extend beyond the frame.
      Positioned(
        left: 0, right: 0, top: 0, height: step * .52,
        child: const IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xBFE5F3FF), Color(0x00E5F3FF)],
          )),
        )),
      ),
    ]));
  });
}

class _ArchitecturalFloor extends StatefulWidget {
  final int floor;
  final int current;
  final VoidCallback onTap;
  const _ArchitecturalFloor({
    required this.floor, required this.current, required this.onTap,
  });
  @override
  State<_ArchitecturalFloor> createState() => _ArchitecturalFloorState();
}

class _ArchitecturalFloorState extends State<_ArchitecturalFloor> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.floor == widget.current;
    final completed = widget.floor < widget.current;
    final game = const FloorEngine().challengeFor(widget.floor).gameId;
    final name = game == 'merge2048' ? '2048' : 'Number Trail';
    final icon = game == 'merge2048' ? '2048' : 'number_trail';
    final skin = active ? 'current' : completed ? 'completed' : 'locked';
    const textColor = Color(0xFF435572);
    return Semantics(
      label: 'Floor ${widget.floor}, $name, ${active ? 'current' : completed ? 'completed' : 'locked'}',
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed ? .978 : 1,
          duration: const Duration(milliseconds: 110),
          child: Stack(children: [
            Positioned.fill(child: Image.asset(
              'assets/art/soft_floor_$skin.webp',
              fit: BoxFit.contain, filterQuality: FilterQuality.high,
            )),
            // A highlighted floor looks illuminated from within the masonry,
            // not covered by a yellow UI rectangle.
            if (active)
              Positioned(
                left: 25, right: 25, top: 25, bottom: 23,
                child: IgnorePointer(child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55FFD782),
                        blurRadius: 19, spreadRadius: 2),
                    ],
                  ),
                )),
              ),
            Positioned(
              left: 52, right: 51, top: 0, bottom: 0,
              child: LayoutBuilder(builder: (context, box) => Align(
                alignment: const Alignment(0, .08),
                child: SizedBox(
                  height: math.min(48.0, box.maxHeight * .53),
                  child: Row(children: [
                    SizedBox(width: 27, child: Text('${widget.floor}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: active ? 22 : 19,
                        fontWeight: FontWeight.w900))),
                    const SizedBox(width: 8),
                    SvgPicture.asset('assets/$icon.svg',
                      height: 37, width: 37),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: active ? 14 : 13,
                        fontWeight: FontWeight.w800))),
                    const SizedBox(width: 2),
                    SvgPicture.asset(active ? 'assets/play.svg'
                      : completed ? 'assets/completed.svg'
                      : 'assets/locked.svg',
                      height: 20, width: 20),
                  ]),
                ),
              )),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TowerShaftPainter extends CustomPainter {
  const _TowerShaftPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rect = Rect.fromLTWH(w * .045, -10, w * .91, size.height + 20);
    canvas.drawRect(rect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0xFFBAC0D6), Color(0xFFF6F1E8),
          Color(0xFFE5DFE7), Color(0xFFB6AFC4)],
        stops: [0, .18, .78, 1],
      ).createShader(rect));
    for (final left in [w * .055, w * .84]) {
      final pillar = Rect.fromLTWH(left, 0, w * .11, size.height);
      canvas.drawRect(pillar, Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFFACB1CB), Color(0xFFE9E4EC), Color(0xFFC9C4D6),
        ]).createShader(pillar));
    }
    // Arcade openings continue between architectural modules.
    final height = size.height / 5;
    for (var i = 0; i < 6; i++) {
      final y = i * height + height * .11;
      for (final x in [w * .065, w * .845]) {
        final niche = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * .075, height * .67),
          Radius.circular(w * .038));
        canvas.drawRRect(niche,
          Paint()..color = const Color(0xFF9BA2BE));
        canvas.drawRRect(niche.deflate(3),
          Paint()..color = const Color(0xFFFFE8B6));
      }
    }
  }
  @override
  bool shouldRepaint(covariant _TowerShaftPainter oldDelegate) => false;
}
