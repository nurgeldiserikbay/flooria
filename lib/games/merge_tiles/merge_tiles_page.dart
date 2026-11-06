import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'merge_tiles_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF5F0E8), surface: Colors.white, ink: Color(0xFF4D4339),
  muted: Color(0xFF938477), accent: Color(0xFF6A9D7B), edge: Color(0xFF4D4339),
);

Widget buildMergeTilesPage(BuildContext context, GameLaunch launch) =>
    MergeTilesPage(launch: launch);

class MergeTilesPage extends StatefulWidget {
  const MergeTilesPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<MergeTilesPage> createState() => _MergeTilesPageState();
}

class _MergeTilesPageState extends State<MergeTilesPage>
    with LevelFlow<MergeTilesPage> {
  late MergeTilesEngine _engine;
  Offset? _dragStart;
  Offset? _dragCurrent;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = MergeTilesEngine.forLevel(level);

  void _move(MergeDirection direction) {
    final result = _engine.move(direction);
    if (result == MergeResult.ignored) return;
    setState(() {});
    if (result == MergeResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == MergeResult.failed) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _endSwipe() {
    final start = _dragStart;
    final end = _dragCurrent;
    _dragStart = null;
    _dragCurrent = null;
    if (start == null || end == null) return;
    final delta = end - start;
    if (delta.distance < 18) return;
    _move(delta.dx.abs() > delta.dy.abs()
        ? delta.dx > 0 ? MergeDirection.right : MergeDirection.left
        : delta.dy > 0 ? MergeDirection.down : MergeDirection.up);
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Merge 2048',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final boardSide = min(constraints.maxWidth - 34,
          constraints.maxHeight - (reported || _engine.isFailed ? 270 : 170))
          .clamp(210.0, 420.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TargetBadge(target: _engine.target),
                StatChip(label: 'SCORE', value: '${_engine.score}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          GestureDetector(
            onPanStart: (details) {
              _dragStart = details.localPosition;
              _dragCurrent = details.localPosition;
            },
            onPanEnd: (_) => _endSwipe(),
            onPanUpdate: (details) {
              _dragCurrent = details.localPosition;
            },
            child: Container(
              width: boardSide,
              height: boardSide,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFB9AA98),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _palette.edge, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x554D4339),
                  offset: Offset(0, 5))]),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: 16,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 7, mainAxisSpacing: 7),
                itemBuilder: (context, index) => _Tile(
                  key: ValueKey('merge-tile-$index'),
                  value: _engine.board[index],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          HintLine(_engine.isCompleted ? 'TARGET REACHED'
              : _engine.isFailed ? 'NO MORE MOVES'
              : 'SWIPE TO MERGE MATCHING TILES', palette: _palette),
          if (reported) ...[
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.score > _engine.target * 3 ? 3
                    : _engine.score > _engine.target ? 2 : 1,
                detail: 'You made ${_engine.target}.',
                onReplay: replayLevel, onNext: nextLevel)),
          ] else if (_engine.isFailed) ...[
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'BOARD FULL',
                detail: 'Try a new tile layout.', onRetry: replayLevel)),
          ],
        ]));
    }),
  );
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.target});
  final int target;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFE1EFD9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF9BB88D))),
    child: Text('GOAL  $target', style: TextStyle(color: _palette.ink,
      fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.value});
  final int value;
  static Color _color(int value) => switch (value) {
    0 => const Color(0xFFD8CCBD),
    2 => const Color(0xFFF5ECDD),
    4 => const Color(0xFFF0DDBA),
    8 => const Color(0xFFF0BF83),
    16 => const Color(0xFFECA96E),
    32 => const Color(0xFFE88D62),
    64 => const Color(0xFFD96E59),
    128 => const Color(0xFFD6C86E),
    256 => const Color(0xFFC8BE5F),
    512 => const Color(0xFFAFB851),
    _ => const Color(0xFF8DAE6E),
  };

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reducedMotion
        ? Duration.zero : const Duration(milliseconds: 180);
    final color = _color(value);
    return Semantics(
      label: value == 0 ? 'Empty tile' : 'Tile $value',
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .22)!,
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
          boxShadow: value == 0 ? null : [
            BoxShadow(
              color: GamePalette.shade(color, .23).withValues(alpha: .65),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: .65, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: value == 0
              ? const SizedBox.shrink(key: ValueKey<int>(0))
              : FittedBox(
                  key: ValueKey<int>(value),
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      '$value',
                      style: TextStyle(
                        color: value <= 4
                            ? const Color(0xFF76695B) : Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
