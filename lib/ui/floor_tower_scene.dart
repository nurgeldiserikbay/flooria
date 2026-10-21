import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/floor_engine.dart';

/// A purely Flutter-rendered, infinitely reusable soft 2.5D tower.
/// Numbers, game names and progress are never embedded in artwork.
class FloorTowerScene extends StatelessWidget {
  final int currentFloor;
  final ValueChanged<int> onFloorTap;
  const FloorTowerScene({
    super.key, required this.currentFloor, required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    // Keep the current floor near the bottom; enough future floors remain
    // visible to communicate progression. Near the start, don't invent zero.
    final bottom = math.max(1, currentFloor - 1);
    final floors = List<int>.generate(4, (i) => bottom + 3 - i);
    final gap = math.min(6.0, box.maxHeight * .015);
    final blockHeight = (box.maxHeight - 3 * gap) / 4;
    return Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 345),
      child: Column(
        children: [
          for (var i = 0; i < floors.length; i++) ...[
            Expanded(child: _SoftFloorBlock(
              floor: floors[i], current: currentFloor,
              onTap: () => onFloorTap(floors[i]),
              availableHeight: blockHeight,
            )),
            if (i != floors.length - 1) SizedBox(height: gap),
          ],
        ],
      ),
    ));
  });
}

class _SoftFloorBlock extends StatelessWidget {
  final int floor;
  final int current;
  final double availableHeight;
  final VoidCallback onTap;
  const _SoftFloorBlock({
    required this.floor, required this.current,
    required this.availableHeight, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = floor == current;
    final complete = floor < current;
    final gameId = const FloorEngine().challengeFor(floor).gameId;
    final gameName = gameId == 'merge2048' ? '2048' : 'Number Trail';
    final foreground = active
      ? const Color(0xFF714D25)
      : complete ? const Color(0xFF426551) : const Color(0xFF77728C);
    final top = active
      ? const Color(0xFFFFE6A2)
      : complete ? const Color(0xFFDDF1DF) : const Color(0xFFE8E6F4);
    final middle = active
      ? const Color(0xFFFFD77E)
      : complete ? const Color(0xFFC7E7D1) : const Color(0xFFDCD9ED);
    final bottom = active
      ? const Color(0xFFE1B46D)
      : complete ? const Color(0xFFA5CDBA) : const Color(0xFFC1BDD7);

    return Semantics(
      label: 'Floor $floor, $gameName, ${active ? 'current' : complete ? 'completed' : 'locked'}',
      button: true,
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: LayoutBuilder(builder: (context, box) {
          final height = box.maxHeight;
          final depth = math.min(11.0, height * .15);
          return Stack(clipBehavior: Clip.none, children: [
            // Continuous soft shadow and bottom extrusion mimic an actual
            // stack of stone blocks without decorative image fragments.
            Positioned(top: depth * .5, left: 4, right: 4, bottom: 0,
              child: DecoratedBox(decoration: BoxDecoration(
                color: bottom, borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(
                  color: Color(0x283F4D71), blurRadius: 14,
                  offset: Offset(0, 7))],
              )),
            ),
            Positioned(top: 0, bottom: depth, left: 0, right: 0,
              child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [top, middle]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .78),
                  width: active ? 2.2 : 1.4),
              )),
            ),
            Positioned(left: 13, right: 13, top: 0,
              child: Container(height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(30)))),
            Positioned(top: 0, bottom: depth, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(children: [
                  SizedBox(width: 29, child: Text('$floor',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground,
                      fontSize: 23, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  _GameSymbol(gameId: gameId,
                    active: active, complete: complete),
                  const SizedBox(width: 12),
                  Expanded(child: Text(gameName, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: foreground,
                      fontSize: 16, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 4),
                  Icon(complete ? Icons.check_circle_rounded :
                    active ? Icons.play_circle_fill_rounded :
                    Icons.lock_outline_rounded,
                    color: active ? const Color(0xFFBB8739) :
                      complete ? const Color(0xFF65A884) :
                      const Color(0xFF9D99B3),
                    size: 22),
                ]),
              ),
            ),
          ]);
        }),
      )),
    );
  }
}

/// Local, consistent icons that work for any floor without image requests.
class _GameSymbol extends StatelessWidget {
  final String gameId;
  final bool active;
  final bool complete;
  const _GameSymbol({
    required this.gameId, required this.active, required this.complete,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .71),
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [BoxShadow(color: Color(0x154C4E6E),
        blurRadius: 5, offset: Offset(0, 3))],
    ),
    child: gameId == 'merge2048' ? GridView.count(
      crossAxisCount: 2, mainAxisSpacing: 2, crossAxisSpacing: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 4; i++)
          DecoratedBox(decoration: BoxDecoration(
            color: [
              const Color(0xFFF4BFA5),
              const Color(0xFFF6D36F),
              const Color(0xFF9DCFF0),
              const Color(0xFFABD6AC),
            ][i],
            borderRadius: BorderRadius.circular(3),
          )),
      ],
    ) : CustomPaint(painter: _TrailSymbol()),
  );
}

class _TrailSymbol extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Paint()
      ..color = const Color(0xFFB4C7B7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width*.18, size.height*.80),
      Offset(size.width*.50, size.height*.24), path);
    canvas.drawLine(Offset(size.width*.50, size.height*.24),
      Offset(size.width*.83, size.height*.66), path);
    final dots = [
      const Color(0xFF89C3F4), const Color(0xFF9ECC9F),
      const Color(0xFFFFA88A)];
    final points = [
      Offset(size.width*.18, size.height*.80),
      Offset(size.width*.50, size.height*.24),
      Offset(size.width*.83, size.height*.66),
    ];
    for (var i=0;i<points.length;i++) {
      canvas.drawCircle(points[i], 5.5, Paint()..color=dots[i]);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
