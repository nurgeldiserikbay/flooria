import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/floor_engine.dart';

/// A viewport into a much taller, reusable tower. Every storey uses one
/// transparent 2.5D architectural sprite and live game/floor information.
class FloorTowerScene extends StatelessWidget {
  final int currentFloor;
  final ValueChanged<int> onFloorTap;
  const FloorTowerScene({
    super.key, required this.currentFloor, required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final first = math.max(1, currentFloor - 1);
    final floors = List<int>.generate(5, (i) => first + 4 - i);
    final step = c.maxHeight / 5;
    return ClipRect(child: Stack(children: [
      for (var i = 0; i < floors.length; i++)
        Positioned(
          top: i * step - 8,
          left: 0, right: 0,
          height: step * 1.44,
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 365),
            child: _ArchitecturalFloor(
              floor: floors[i], current: currentFloor,
              onTap: () => onFloorTap(floors[i]),
            ),
          )),
        ),
    ]));
  });
}

class _ArchitecturalFloor extends StatelessWidget {
  final int floor;
  final int current;
  final VoidCallback onTap;
  const _ArchitecturalFloor({
    required this.floor, required this.current, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final active = floor == current;
    final completed = floor < current;
    final game = const FloorEngine().challengeFor(floor).gameId;
    final name = game == 'merge2048' ? '2048' : 'Number Trail';
    final symbol = game == 'merge2048' ? '2048' : 'number_trail';
    final sprite = active ? 'current' : completed ? 'completed' : 'locked';
    const dark = Color(0xFF455779);
    return Semantics(
      label: 'Floor $floor, $name, ${active ? 'current' : completed ? 'completed' : 'locked'}',
      button: true,
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(builder: (context, c) {
          return Stack(children: [
            Positioned.fill(child: Image.asset(
              'assets/art/soft_floor_$sprite.webp',
              fit: BoxFit.fill, filterQuality: FilterQuality.medium,
            )),
            Positioned(
              left: c.maxWidth * .21,
              right: c.maxWidth * .20,
              top: c.maxHeight * .35,
              bottom: c.maxHeight * .28,
              child: Row(children: [
                Text('$floor', style: TextStyle(
                  fontSize: active ? 23 : 20,
                  fontWeight: FontWeight.w900, color: dark,
                )),
                const SizedBox(width: 7),
                SvgPicture.asset('assets/$symbol.svg',
                  height: 37, width: 37, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Expanded(child: Text(name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: dark,
                    fontSize: 13, fontWeight: FontWeight.w800))),
                SvgPicture.asset(
                  active ? 'assets/play.svg' :
                    completed ? 'assets/completed.svg' : 'assets/locked.svg',
                  height: 22, width: 22,
                ),
              ]),
            ),
          ]);
        }),
      )),
    );
  }
}
