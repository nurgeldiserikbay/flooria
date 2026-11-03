import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'color_catcher_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF4EC), surface: Colors.white, ink: Color(0xFF3E5944),
  muted: Color(0xFF7E967F), accent: Color(0xFF5DAE76), edge: Color(0xFF3E5944),
);

Widget buildColorCatcherPage(BuildContext context, GameLaunch launch) =>
    ColorCatcherPage(launch: launch);

class ColorCatcherPage extends StatefulWidget {
  const ColorCatcherPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<ColorCatcherPage> createState() => _ColorCatcherPageState();
}

class _ColorCatcherPageState extends State<ColorCatcherPage> with LevelFlow<ColorCatcherPage> {
  late ColorCatcherEngine _engine;
  Timer? _timer;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _timer?.cancel();
    _engine = ColorCatcherEngine.forLevel(level);
    _timer = Timer.periodic(Duration(milliseconds: _engine.intervalMilliseconds), (_) {
      if (!mounted) return;
      final result = _engine.tick();
      if (result == CatchTick.ignored) return;
      setState(() {});
      if (result == CatchTick.completed) {
        _timer?.cancel();
        HapticFeedback.mediumImpact();
        reportWin(score: _engine.score, metrics: const {});
      } else if (result == CatchTick.failed) {
        _timer?.cancel();
        HapticFeedback.vibrate();
      }
    });
  }

  void _move(int direction) {
    if (_engine.moveBasket(direction) == CatchMove.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Color Catcher',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final boardWidth = min(constraints.maxWidth - 34,
        (constraints.maxHeight - (reported || _engine.isFailed ? 245 : 185)) *
            ColorCatcherEngine.lanes / ColorCatcherEngine.rows)
        .clamp(220.0, 360.0).toDouble();
      final boardHeight = boardWidth * ColorCatcherEngine.rows / ColorCatcherEngine.lanes;
      final byCell = {for (final token in _engine.tokens)
        token.row * ColorCatcherEngine.lanes + token.lane: token};
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'FRUIT', value: '${_engine.caught}/${_engine.goal}', palette: _palette),
                StatChip(label: 'BOMBS', value: '${_engine.strikes}/3', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Container(width: boardWidth, height: boardHeight, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFC8DDCA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: ColorCatcherEngine.lanes * ColorCatcherEngine.rows,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ColorCatcherEngine.lanes,
                crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final row = cell ~/ ColorCatcherEngine.lanes;
                final token = byCell[cell];
                final bucket = row == ColorCatcherEngine.rows - 1 &&
                    cell % ColorCatcherEngine.lanes == _engine.basketLane;
                return AnimatedContainer(duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(color: bucket ? const Color(0xFFB5DDBB)
                    : const Color(0xFFE6EFE3), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: bucket ? _palette.accent
                      : const Color(0xFFD1E0D0), width: bucket ? 2 : 1)),
                  child: Center(child: token != null
                    ? Icon(token.kind == CatchKind.fruit
                        ? Icons.local_florist_rounded : Icons.brightness_1_rounded,
                      size: boardWidth / 16,
                      color: token.kind == CatchKind.fruit
                        ? const Color(0xFFE47A50) : const Color(0xFF58585C))
                    : bucket ? const Icon(Icons.shopping_basket_rounded,
                        size: 27, color: Color(0xFF477A50)) : null),
                );
              },
            )),
          const SizedBox(height: 12),
          if (!reported && !_engine.isFailed)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChunkyIconButton(icon: Icons.arrow_left_rounded, tooltip: 'Move left',
                palette: _palette, onPressed: () => _move(-1)),
              const SizedBox(width: 24),
              ChunkyIconButton(icon: Icons.arrow_right_rounded, tooltip: 'Move right',
                palette: _palette, onPressed: () => _move(1)),
            ]),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.strikes == 0 ? 3 : _engine.strikes == 1 ? 2 : 1,
                detail: 'Collected every fruit and avoided the bombs.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'TOO MANY BOMBS',
                detail: 'Move the basket away from dark bombs.', onRetry: replayLevel))
          else
            const HintLine('CATCH FRUIT · DODGE THE DARK BOMBS', palette: _palette),
        ]));
    }),
  );
}
