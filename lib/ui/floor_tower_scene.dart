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
    final gap = 0.0;
    return Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 345),
      child: Column(
        children: [
          for (var i = 0; i < floors.length; i++) ...[
            Expanded(child: _SoftFloorBlock(
              floor: floors[i], current: currentFloor,
              onTap: () => onFloorTap(floors[i]),
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
  final VoidCallback onTap;
  const _SoftFloorBlock({
    required this.floor, required this.current,
    required this.onTap,
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
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(builder: (context, box) {
          final height = box.maxHeight;
          final depth = math.min(11.0, height * .14);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: CustomPaint(
              painter: _ArchitecturalFloorPainter(
                upper: top, front: middle, edge: bottom,
                active: active,
              ),
            )),
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
                    ),
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

/// One coherent architecture for every level: continuous side piers,
/// softly lit arcade niches, projecting stone cornices and pastel facade.
class _ArchitecturalFloorPainter extends CustomPainter {
  final Color upper;
  final Color front;
  final Color edge;
  final bool active;
  const _ArchitecturalFloorPainter({
    required this.upper, required this.front,
    required this.edge, required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = Paint();
    final under = Rect.fromLTWH(w*.025, h*.10, w*.95, h*.88);
    canvas.drawRRect(RRect.fromRectAndRadius(under, const Radius.circular(13)),
      Paint()..color = edge);
    final facade = Rect.fromLTWH(w*.048, h*.07, w*.904, h*.81);
    frame.shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [upper, front],
    ).createShader(facade);
    canvas.drawRRect(RRect.fromRectAndRadius(
      facade, const Radius.circular(12)), frame);
    frame.shader = null;

    // Arcade niches tie separate levels together visually.
    for (final side in [0.01, .86]) {
      final rect = Rect.fromLTWH(w*side, h*.18, w*.13, h*.62);
      canvas.drawRRect(RRect.fromRectAndRadius(rect,
        Radius.circular(w*.065)), Paint()
          ..color = const Color(0x36FFFFFF));
      final inset = rect.deflate(math.min(w*.022, h*.09));
      canvas.drawRRect(RRect.fromRectAndRadius(inset,
        Radius.circular(w*.055)), Paint()
          ..color = edge.withValues(alpha: .33));
      canvas.drawRRect(RRect.fromRectAndRadius(inset,
        Radius.circular(w*.055)), Paint()
          ..color = const Color(0x60FFFFFF)
          ..style = PaintingStyle.stroke ..strokeWidth = 1.2);
    }

    // Subtle stone pilasters (avoid a flat card silhouette).
    for (final x in [.125, .82]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*x, h*.14, w*.045, h*.69),
        const Radius.circular(5)),
        Paint()..color = const Color(0x43FFFFFF));
    }

    // The cornice is wider than the facade, and overlaps the next storey.
    final ledge = Path()
      ..moveTo(w*.018, h*.06)
      ..lineTo(w*.085, h*.008)
      ..lineTo(w*.915, h*.008)
      ..lineTo(w*.982, h*.06)
      ..lineTo(w*.970, h*.17)
      ..lineTo(w*.03, h*.17)
      ..close();
    canvas.drawPath(ledge, Paint()..color = upper);
    canvas.drawLine(Offset(w*.04,h*.17), Offset(w*.96,h*.17),
      Paint()..color=const Color(0x80FFFFFF)..strokeWidth=2);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w*.035,h*.82,w*.93,h*.11),
      const Radius.circular(5)), Paint()..color=edge);
    canvas.drawLine(Offset(w*.043,h*.82), Offset(w*.957,h*.82),
      Paint()..color=const Color(0xBFFFFFFF)..strokeWidth=2);

    // Restrained living detail, not photorealistic collage.
    final leaf = Paint()..color = const Color(0xFF92BA87);
    for (final x in [.07, .93]) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(w*x, h*.055),
        width: w*.037, height: h*.11), leaf);
      canvas.drawOval(Rect.fromCenter(
        center: Offset(w*(x+ (x<.5 ? .03 : -.03)),h*.085),
        width: w*.038,height: h*.09), leaf);
    }

    if (active) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*.14,h*.2,w*.72,h*.55),
        const Radius.circular(13)),
        Paint()..color=const Color(0x42FFFFFF));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*.14,h*.2,w*.72,h*.55),
        const Radius.circular(13)),
        Paint()..color=const Color(0xBFFFF7DE)
          ..strokeWidth=1.7..style=PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalFloorPainter old) =>
    old.upper != upper || old.front != front ||
    old.edge != edge || old.active != active;
}

/// Local, consistent icons that work for any floor without image requests.
class _GameSymbol extends StatelessWidget {
  final String gameId;
  const _GameSymbol({
    required this.gameId,
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
