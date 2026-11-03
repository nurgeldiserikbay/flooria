import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'picture_assemble_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF4F8), surface: Colors.white, ink: Color(0xFF3D5661),
  muted: Color(0xFF7D969E), accent: Color(0xFF59A8B2), edge: Color(0xFF3D5661),
);

Widget buildPictureAssemblePage(BuildContext context, GameLaunch launch) =>
    PictureAssemblePage(launch: launch);

class PictureAssemblePage extends StatefulWidget {
  const PictureAssemblePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<PictureAssemblePage> createState() => _PictureAssemblePageState();
}

class _PictureAssemblePageState extends State<PictureAssemblePage>
    with LevelFlow<PictureAssemblePage> {
  late PictureAssembleEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = PictureAssembleEngine.forLevel(level);

  void _tap(int cell) {
    final result = _engine.tap(cell);
    if (result == PictureMove.ignored) return;
    if (result == PictureMove.blocked) {
      HapticFeedback.selectionClick();
      return;
    }
    setState(() {});
    if (result == PictureMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Picture Assembly', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 32,
        constraints.maxHeight - (reported ? 280 : 220)).clamp(235.0, 370.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              const SizedBox(width: 12),
              const Expanded(child: HintLine('RESTORE THE SCENE', palette: _palette)),
              const SizedBox(width: 8),
              CustomPaint(size: const Size(54, 54), painter: _ScenePreviewPainter()),
            ])),
          const SizedBox(height: 12),
          Container(width: side, height: side, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFC7DDE2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: _engine.tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: PictureAssembleEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final tile = _engine.tiles[cell];
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _tap(cell),
                    borderRadius: BorderRadius.circular(7),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                      decoration: BoxDecoration(color: tile == 0
                        ? const Color(0xFFDCE9E9) : Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: tile == 0
                          ? const Color(0xFFAFC6C8) : Colors.white, width: 2)),
                      child: tile == 0
                        ? const Center(child: Icon(Icons.circle_outlined,
                            color: Color(0xFFAAC0C3), size: 18))
                        : CustomPaint(painter: _SceneFragmentPainter(tile - 1)),
                    )),
                );
              },
            )),
          const SizedBox(height: 12),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 24 ? 3 : _engine.moves <= 42 ? 2 : 1,
                detail: 'Put every picture fragment back in place.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('TAP A TILE NEXT TO THE EMPTY SPACE', palette: _palette),
        ]));
    }),
  );
}

class _ScenePreviewPainter extends CustomPainter {
  const _ScenePreviewPainter();
  @override
  void paint(Canvas canvas, Size size) => _drawScene(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(covariant _ScenePreviewPainter oldDelegate) => false;
}

class _SceneFragmentPainter extends CustomPainter {
  const _SceneFragmentPainter(this.fragment);
  final int fragment;
  @override
  void paint(Canvas canvas, Size size) {
    final row = fragment ~/ PictureAssembleEngine.side;
    final col = fragment % PictureAssembleEngine.side;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((-col * size.width).toDouble(), (-row * size.height).toDouble());
    _drawScene(canvas, Rect.fromLTWH(0, 0,
      size.width * PictureAssembleEngine.side,
      size.height * PictureAssembleEngine.side));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _SceneFragmentPainter oldDelegate) => oldDelegate.fragment != fragment;
}

void _drawScene(Canvas canvas, Rect rect) {
  canvas.drawRect(rect, Paint()..shader = const LinearGradient(
    colors: [Color(0xFF8FD0E1), Color(0xFFD6EDDC)], begin: Alignment.topCenter,
    end: Alignment.bottomCenter).createShader(rect));
  final sunCenter = Offset(rect.left + rect.width * .73, rect.top + rect.height * .25);
  canvas.drawCircle(sunCenter, rect.width * .105, Paint()..color = const Color(0xFFFFD36B));
  final farHill = Path()
    ..moveTo(rect.left, rect.top + rect.height * .64)
    ..lineTo(rect.left + rect.width * .25, rect.top + rect.height * .34)
    ..lineTo(rect.left + rect.width * .46, rect.top + rect.height * .61)
    ..lineTo(rect.left + rect.width * .72, rect.top + rect.height * .38)
    ..lineTo(rect.right, rect.top + rect.height * .65)
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();
  canvas.drawPath(farHill, Paint()..color = const Color(0xFF6FA998));
  final nearHill = Path()
    ..moveTo(rect.left, rect.top + rect.height * .77)
    ..quadraticBezierTo(rect.width * .45, rect.top + rect.height * .53,
      rect.right, rect.top + rect.height * .78)
    ..lineTo(rect.right, rect.bottom)
    ..lineTo(rect.left, rect.bottom)
    ..close();
  canvas.drawPath(nearHill, Paint()..color = const Color(0xFF3E8977));
  final river = Path()
    ..moveTo(rect.left + rect.width * .38, rect.bottom)
    ..cubicTo(rect.width * .5, rect.height * .86, rect.width * .65,
      rect.height * .92, rect.width * .78, rect.bottom)
    ..close();
  canvas.drawPath(river, Paint()..color = const Color(0xFF74C4D0));
}
