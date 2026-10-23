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
    // A window onto an endless tower: show four readable storeys, with the
    // current level at the bottom and upcoming levels extending into clouds.
    final first = math.max(1, currentFloor - 2);
    final floors = List<int>.generate(4, (i) => first + 3 - i);
    final step = box.maxHeight / 3.72;
    final moduleWidth = math.min(math.min(box.maxWidth, 420.0),
      step * (900 / 305) * 1.18);
    final moduleHeight = moduleWidth * (305 / 900);
    final shaftWidth = moduleWidth * .77;

    return ClipRect(child: Stack(children: [
      // Connected interior masonry is visible through the small gaps between
      // overlapping sculpted cornices.
      Positioned(
        top: -20, bottom: -30,
        left: (box.maxWidth - shaftWidth) / 2,
        width: shaftWidth,
        child: const CustomPaint(painter: _TowerShaftPainter()),
      ),
      for (var i = 0; i < floors.length; i++)
        Positioned(
          top: i * step - moduleHeight * .22,
          left: 0, right: 0,
          height: moduleHeight,
          child: Center(child: SizedBox(
            width: moduleWidth * (1 - i * .012),
            height: moduleHeight,
            child: _ArchitecturalFloor(
              key: ValueKey<int>(floors[i]),
              floor: floors[i],
              current: currentFloor,
              onTap: () => onFloorTap(floors[i]),
            ),
          )),
        ),
      if (currentFloor <= 2)
        Positioned(
          left: 0, right: 0, bottom: -24,
          height: math.min(100, box.maxHeight * .29),
          child: IgnorePointer(child: SvgPicture.asset(
            'assets/tower/tower_base.svg',
            fit: BoxFit.fill,
          )),
        ),
      // Small foreground cloud veil merges the stairway into the sky,
      // so the end of the tower does not look abruptly cropped.
      Positioned(
        left: 0, right: 0, bottom: -4,
        height: math.min(38, box.maxHeight * .11),
        child: const IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00FFFDFC), Color(0xD9FFFDFC)],
          )),
        )),
      ),
      // The uppermost storey disappears into distance rather than terminating.
      Positioned(
        left: 0, right: 0, top: 0, height: step * .4,
        child: const IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xB7DCEFFE), Color(0x00DCEFFE)],
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
    super.key,
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
            Positioned.fill(child: SvgPicture.asset(
              'assets/tower/floor_$skin.svg',
              fit: BoxFit.fill,
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
              left: 0, right: 0,
              top: 0, bottom: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Align(
                alignment: const Alignment(0, .23),
                child: FractionallySizedBox(
                  heightFactor: .41,
                  child: Row(children: [
                    SizedBox(width: 30,
                      child: FittedBox(fit: BoxFit.scaleDown,
                        child: Text('${widget.floor}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: active ? 23 : 20,
                            fontWeight: FontWeight.w900)))),
                    const SizedBox(width: 8),
                    if (!active && !completed)
                      SvgPicture.asset('assets/locked.svg',
                        height: 37, width: 37)
                    else
                      SvgPicture.asset('assets/$icon.svg',
                        height: 37, width: 37),
                    const SizedBox(width: 8),
                    if (active)
                      Expanded(child: Text(name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textColor,
                          fontSize: 14, fontWeight: FontWeight.w800)))
                    else if (!completed)
                      const Expanded(child: Text('Coming Soon',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF83819A),
                          fontSize: 12, fontWeight: FontWeight.w700)))
                    else
                      const Spacer(),
                    if (active || completed)
                      SvgPicture.asset(active ? 'assets/play.svg'
                        : 'assets/completed.svg',
                        height: 21, width: 21),
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
