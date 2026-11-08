import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'billiards_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE8F3EC), surface: Colors.white, ink: Color(0xFF36554A),
  muted: Color(0xFF779286), accent: Color(0xFF54A27F), edge: Color(0xFF36554A),
);
const _ballColors = [Color(0xFFE9B64E), Color(0xFF5E9DD2), Color(0xFFE87973),
  Color(0xFF8A72C4), Color(0xFF54AA8D), Color(0xFFE59352),
  Color(0xFF6381B9), Color(0xFFBD6F9B)];

Widget buildBilliardsPage(BuildContext context, GameLaunch launch) =>
    BilliardsPage(launch: launch);

class BilliardsPage extends StatefulWidget {
  const BilliardsPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<BilliardsPage> createState() => _BilliardsPageState();
}

class _BilliardsPageState extends State<BilliardsPage> with LevelFlow<BilliardsPage> {
  late BilliardsEngine _engine;
  String _feedback = 'POCKET THE BALLS IN NUMBER ORDER';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = BilliardsEngine.forLevel(level);
    _feedback = 'POCKET THE BALLS IN NUMBER ORDER';
  }

  void _shoot(BilliardDirection direction) {
    final result = _engine.shoot(direction);
    if (result == BilliardShot.ignored) return;
    setState(() => _feedback = result == BilliardShot.missed
        ? 'WRONG BALL · FIND NUMBER ${_engine.nextNumber}'
        : result == BilliardShot.completed
            ? 'ALL BALLS POCKETED'
            : 'GREAT SHOT · FIND NUMBER ${_engine.nextNumber}');
    if (result == BilliardShot.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == BilliardShot.missed) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Billiard Order', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth - 36,
        constraints.maxHeight - (reported || _engine.isFailed ? 390 : 330))
        .clamp(205.0, 340.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'NEXT BALL', value: '${_engine.nextNumber}', palette: _palette),
              StatChip(label: 'MISSES', value: '${_engine.misses}/${_engine.maxMisses}', palette: _palette),
            ])),
          const SizedBox(height: 10),
          Semantics(
            key: const ValueKey('billiard-table-state'),
            label: 'Billiards table. Next ball ${_engine.nextNumber}. '
                '${_engine.remaining.map((ball) => 'Ball ${ball.number} ${ball.direction.name}').join(', ')}',
            child: CustomPaint(
              key: const ValueKey('billiard-table'),
              size: Size(size, size), painter: _BilliardPainter(_engine))),
          const SizedBox(height: 8),
          _AimPad(onShoot: _shoot, disabled: reported || _engine.isFailed),
          const SizedBox(height: 4),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.misses == 0 ? 3 : _engine.misses == 1 ? 2 : 1,
                detail: 'Pocketed every ball in order.', onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'FOULS USED',
                detail: 'Aim at the ball with the next number.', onRetry: replayLevel))
          else
            HintLine(_feedback, palette: _palette),
        ]));
    }),
  );
}

class _AimPad extends StatelessWidget {
  const _AimPad({required this.onShoot, required this.disabled});
  final ValueChanged<BilliardDirection> onShoot;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    const directions = [
      BilliardDirection.upLeft, BilliardDirection.up, BilliardDirection.upRight,
      BilliardDirection.left, null, BilliardDirection.right,
      BilliardDirection.downLeft, BilliardDirection.down, BilliardDirection.downRight,
    ];
    const icons = [Icons.north_west_rounded, Icons.keyboard_arrow_up_rounded,
      Icons.north_east_rounded, Icons.keyboard_arrow_left_rounded, null,
      Icons.keyboard_arrow_right_rounded, Icons.south_west_rounded,
      Icons.keyboard_arrow_down_rounded, Icons.south_east_rounded];
    return SizedBox(width: 150, child: GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: directions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
      itemBuilder: (context, cell) => directions[cell] == null
        ? const Center(child: Icon(Icons.circle, color: Color(0xFF36554A), size: 12))
        : ChunkyIconButton(icon: icons[cell]!, tooltip: 'Shoot ${directions[cell]!.name}',
            palette: _palette, onPressed: disabled ? null : () => onShoot(directions[cell]!)),
    ));
  }
}

class _BilliardPainter extends CustomPainter {
  const _BilliardPainter(this.engine);
  final BilliardsEngine engine;
  static const _positions = <BilliardDirection, Offset>{
    BilliardDirection.up: Offset(.50, .17),
    BilliardDirection.upRight: Offset(.78, .25),
    BilliardDirection.right: Offset(.83, .50),
    BilliardDirection.downRight: Offset(.78, .75),
    BilliardDirection.down: Offset(.50, .83),
    BilliardDirection.downLeft: Offset(.22, .75),
    BilliardDirection.left: Offset(.17, .50),
    BilliardDirection.upLeft: Offset(.22, .25),
  };
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()..color = const Color(0xFF408263));
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(7), const Radius.circular(18)),
      Paint()..color = const Color(0xFF71AF83));
    final pocketRadius = size.shortestSide * .045;
    for (final point in [const Offset(.06, .06), const Offset(.94, .06),
      const Offset(.06, .94), const Offset(.94, .94)]) {
      canvas.drawCircle(Offset(point.dx * size.width, point.dy * size.height),
        pocketRadius, Paint()..color = const Color(0xFF28483C));
    }
    final cue = Offset(size.width * .5, size.height * .5);
    canvas.drawCircle(cue, size.shortestSide * .075,
      Paint()..color = const Color(0xFFF8F7E9));
    canvas.drawCircle(cue - Offset(size.width * .018, size.height * .018),
      size.shortestSide * .028,
      Paint()..color = Colors.white.withValues(alpha: .8));
    for (final ball in engine.remaining) {
      final position = _positions[ball.direction]!;
      final center = Offset(position.dx * size.width, position.dy * size.height);
      final radius = size.shortestSide * .075;
      final next = ball.number == engine.nextNumber;
      if (next) {
        canvas.drawCircle(center, radius * 1.27,
          Paint()..color = const Color(0xFFFFE9A5).withValues(alpha: .68));
      }
      canvas.drawCircle(center, radius,
        Paint()..color = _ballColors[(ball.number - 1) % _ballColors.length]);
      canvas.drawCircle(center - Offset(radius * .23, radius * .29),
        radius * .31, Paint()..color = Colors.white.withValues(alpha: .38));
      canvas.drawCircle(center, radius, Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 2);
      final painter = TextPainter(text: TextSpan(text: '${ball.number}',
        style: const TextStyle(color: Color(0xFF324A3E), fontSize: 14,
          fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
      painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    }
    canvas.drawCircle(cue, size.shortestSide * .04,
      Paint()..color = const Color(0xFF38594A));
  }
  @override
  bool shouldRepaint(covariant _BilliardPainter oldDelegate) => true;
}
