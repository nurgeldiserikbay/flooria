import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/floor_engine.dart';

/// A moving four-floor viewport made from artist-authored empty architectural
/// layers. The visuals contain no baked labels, so progression can be infinite.
/// Each piece comes from the SAME tower and overlaps its neighbor's cornice.
class FloorTowerScene extends StatelessWidget {
  const FloorTowerScene({
    super.key,
    required this.currentFloor,
    required this.onFloorTap,
  });
  final int currentFloor;
  final ValueChanged<int> onFloorTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final first = math.max(1, currentFloor - 2);
    final floors = List<int>.generate(4, (i) => first + 3 - i);
    final step = box.maxHeight / 4.2;
    final width = math.min(box.maxWidth * .91, math.min(380.0, step * 3.27));
    final segmentHeight = step * 1.15;
    final offset = -segmentHeight * .18;

    return ClipRect(child: Stack(children: [
      for (var i = 0; i < floors.length; i++)
        Positioned(
          top: i * step + offset,
          left: (box.maxWidth - width) / 2,
          width: width,
          height: segmentHeight,
          child: _ArtworkFloor(
            key: ValueKey(floors[i]),
            floor: floors[i], current: currentFloor,
            onTap: () => onFloorTap(floors[i]),
          ),
        ),
      if (currentFloor <= 2)
        Positioned(
          left: (box.maxWidth - width) / 2 - 6,
          width: width + 12, bottom: -62, height: 99,
          child: IgnorePointer(child: Image.asset(
            'assets/design/tower-base.webp',
            fit: BoxFit.fill, filterQuality: FilterQuality.high,
          )),
        ),
      // The sky is clear. Only the farthest architecture dissolves at the top.
      Positioned(
        left: 0, right: 0, top: 0, height: step * .21,
        child: const IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x8CB9E0FC), Color(0x00B9E0FC)],
          )),
        )),
      ),
    ]));
  });
}

class _ArtworkFloor extends StatefulWidget {
  const _ArtworkFloor({
    super.key, required this.floor,
    required this.current, required this.onTap,
  });
  final int floor;
  final int current;
  final VoidCallback onTap;
  @override
  State<_ArtworkFloor> createState() => _ArtworkFloorState();
}

class _ArtworkFloorState extends State<_ArtworkFloor> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.floor == widget.current;
    final completed = widget.floor < widget.current;
    final gameId = const FloorEngine().challengeFor(widget.floor).gameId;
    final name = gameId == 'merge2048' ? '2048' : 'Number Trail';
    final icon = gameId == 'merge2048'
        ? 'assets/2048.svg' : 'assets/number_trail.svg';
    final skin = active ? 'current' : completed ? 'completed' : 'locked';

    return Semantics(
      button: true,
      label: 'Floor ${widget.floor}, ${active ? name : completed ? 'completed' : 'locked'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => down = true),
        onTapUp: (_) => setState(() => down = false),
        onTapCancel: () => setState(() => down = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 125),
          scale: down ? .988 : 1.0,
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            return Stack(children: [
              Positioned.fill(child: Image.asset(
                'assets/design/tower-$skin.webp',
                fit: BoxFit.fill, filterQuality: FilterQuality.high,
              )),
              Positioned(
                left: w * .25, right: w * .115,
                top: 0, bottom: 0,
                child: Align(
                  alignment: const Alignment(0, .15),
                  child: SizedBox(
                    height: math.min(51, box.maxHeight * .45),
                    child: Row(children: [
                      SizedBox(width: 32,
                        child: FittedBox(fit: BoxFit.scaleDown,
                          child: Text('${widget.floor}',
                            style: TextStyle(
                              color: active ? const Color(0xFF855522)
                                : completed ? const Color(0xFF416F4B)
                                : const Color(0xFF67678B),
                              fontSize: active ? 24 : 22,
                              fontWeight: FontWeight.w900,
                            ))),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        completed || active ? icon : 'assets/locked.svg',
                        height: active ? 39 : 36,
                        width: active ? 39 : 36,
                      ),
                      const SizedBox(width: 8),
                      if (active)
                        Expanded(child: Text(name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF72502E), fontSize: 14,
                            fontWeight: FontWeight.w900)))
                      else
                        const Spacer(),
                      if (completed)
                        SvgPicture.asset('assets/completed.svg',
                          width: 21, height: 21),
                    ]),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
