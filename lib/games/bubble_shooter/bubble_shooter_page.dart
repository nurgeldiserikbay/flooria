import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'bubble_shooter_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF5FF), surface: Colors.white, ink: Color(0xFF38516B),
  muted: Color(0xFF7B93A9), accent: Color(0xFF579BD0), edge: Color(0xFF38516B),
);
const _bubbles = [Color(0xFFE87579), Color(0xFFF0B94F), Color(0xFF5DB6A2),
  Color(0xFF638FDB), Color(0xFFA579C5)];

Widget buildBubbleShooterPage(BuildContext context, GameLaunch launch) =>
    BubbleShooterPage(launch: launch);

class BubbleShooterPage extends StatefulWidget {
  const BubbleShooterPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<BubbleShooterPage> createState() => _BubbleShooterPageState();
}

class _BubbleShooterPageState extends State<BubbleShooterPage> with LevelFlow<BubbleShooterPage> {
  late BubbleShooterEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = BubbleShooterEngine.forLevel(level);

  void _shoot(int column) {
    final result = _engine.shootAt(column);
    if (result == BubbleShot.ignored || result == BubbleShot.blocked) return;
    setState(() {});
    if (result == BubbleShot.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Bubble Shooter', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final width = min(constraints.maxWidth - 28,
        (constraints.maxHeight - (reported || _engine.isFailed ? 290 : 225)) *
          BubbleShooterEngine.columns / BubbleShooterEngine.rows)
        .clamp(230.0, 360.0).toDouble();
      final height = width * BubbleShooterEngine.rows / BubbleShooterEngine.columns;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'POPPED', value: '${_engine.popped}/${_engine.goal}', palette: _palette),
              StatChip(label: 'SHOTS', value: '${_engine.shots}', palette: _palette),
            ])),
          const SizedBox(height: 12),
          Container(width: width, height: height, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFC8DDED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: _engine.board.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: BubbleShooterEngine.columns,
                crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final bubble = _engine.board[cell];
                final col = cell % BubbleShooterEngine.columns;
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported || _engine.isFailed ? null : () => _shoot(col),
                    borderRadius: BorderRadius.circular(7),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 130),
                      decoration: BoxDecoration(color: const Color(0xFFE7F1F7),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFD3E2EB))),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: bubble == null
                              ? const SizedBox.shrink(key: ValueKey('empty'))
                              : _GlossyBubble(
                                  key: ValueKey('bubble-$bubble'),
                                  color: _bubbles[bubble],
                                  size: width / 10,
                                ),
                        ),
                      ),
                    )),
                );
              },
            )),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                  ? Duration.zero : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _GlossyBubble(
                key: ValueKey('next-${_engine.currentColor}'),
                color: _bubbles[_engine.currentColor],
                size: 42,
              ),
            ),
          ]),
          const HintLine('TAP A COLUMN TO SHOOT', palette: _palette),
          const SizedBox(height: 10),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.shots <= _engine.goal ? 3 : _engine.shots <= _engine.goal + 5 ? 2 : 1,
                detail: 'Popped enough bubbles to clear the room.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'BOARD FULL',
                detail: 'Clear matching groups to make room.', onRetry: replayLevel))
        ]));
    }),
  );
}

class _GlossyBubble extends StatelessWidget {
  const _GlossyBubble({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.34, -.48),
          radius: 1.05,
          colors: [
            Color.lerp(color, Colors.white, .52)!,
            color,
            GamePalette.shade(color, .22),
          ],
          stops: const [0, .62, 1],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .42),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-.38, -.40),
        child: Container(
          width: size * .24,
          height: size * .12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .80),
            borderRadius: BorderRadius.circular(size * .1),
          ),
        ),
      ),
    ),
  );
}
