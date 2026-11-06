import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'sokoban_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF3EFE5), surface: Colors.white, ink: Color(0xFF514638),
  muted: Color(0xFF8B806F), accent: Color(0xFFBA8A50), edge: Color(0xFF514638),
);

Widget buildSokobanPage(BuildContext context, GameLaunch launch) =>
    SokobanPage(launch: launch);

class SokobanPage extends StatefulWidget {
  const SokobanPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<SokobanPage> createState() => _SokobanPageState();
}

class _SokobanPageState extends State<SokobanPage> with LevelFlow<SokobanPage> {
  late SokobanEngine _engine;
  int _blockedPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = SokobanEngine.forLevel(level);
    _blockedPulse = 0;
  }

  void _move(CrateDirection direction) {
    final result = _engine.move(direction);
    if (result == SokobanMove.ignored || result == SokobanMove.blocked) {
      if (result == SokobanMove.blocked) {
        HapticFeedback.selectionClick();
        setState(() => _blockedPulse++);
      }
      return;
    }
    setState(() {});
    if (result == SokobanMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Sokoban',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported ? 245 : 215)).clamp(250.0, 430.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'CRATES', value: '${_engine.goals.length}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 12),
          Shake(
            trigger: _blockedPulse,
            child: Container(
              width: side,
              height: side,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFECDDBE), Color(0xFFCBB89A)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _palette.edge, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _palette.edge.withValues(alpha: .55),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: SokobanEngine.side * SokobanEngine.side,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: SokobanEngine.side,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemBuilder: (context, cell) => _Cell(
                  key: ValueKey('sokoban-cell-$cell'),
                  wall: _engine.isWall(cell),
                  crate: _engine.crates.contains(cell),
                  goal: _engine.goals.contains(cell),
                  player: _engine.player == cell,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!reported) _DirectionPad(onMove: _move),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 8 + level ? 3 : 2,
                detail: 'Every crate reached a marked pad.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('PUSH EVERY CRATE ONTO A GOLD PAD', palette: _palette),
        ]));
    }),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.wall,
    required this.crate,
    required this.goal,
    required this.player,
  });

  final bool wall, crate, goal, player;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero : const Duration(milliseconds: 175);
    final top = wall ? const Color(0xFFAC967D)
        : goal ? const Color(0xFFFFE6A1) : const Color(0xFFF6ECDD);
    final bottom = wall ? const Color(0xFF85705C)
        : goal ? const Color(0xFFEED18B) : const Color(0xFFE9DCC7);
    return Semantics(
      label: wall ? 'Wall' : crate && goal ? 'Crate on goal'
          : crate ? 'Crate' : player ? 'Player'
          : goal ? 'Goal' : 'Floor',
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: wall ? const Color(0xFF78654F) : const Color(0xFFD7CBB7),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (goal)
              Icon(Icons.radio_button_checked_rounded,
                size: 17, color: crate
                    ? const Color(0xFF52866B) : const Color(0xFFB58B36)),
            AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: crate
                  ? Container(
                      key: const ValueKey('crate'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFF3B972), Color(0xFFC88947),
                        ]),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF8B592E), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55875A33),
                            offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        size: 15, color: Color(0xFF754926),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-crate')),
            ),
            AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: player
                  ? const Icon(Icons.face_rounded,
                      key: ValueKey('player'),
                      size: 23, color: Color(0xFF368B69))
                  : const SizedBox.shrink(key: ValueKey('no-player')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onMove});
  final ValueChanged<CrateDirection> onMove;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min,
    children: [
      _Arrow(icon: Icons.keyboard_arrow_up_rounded, onTap: () => onMove(CrateDirection.up)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _Arrow(icon: Icons.keyboard_arrow_left_rounded, onTap: () => onMove(CrateDirection.left)),
        const SizedBox(width: 48),
        _Arrow(icon: Icons.keyboard_arrow_right_rounded, onTap: () => onMove(CrateDirection.right)),
      ]),
      _Arrow(icon: Icons.keyboard_arrow_down_rounded, onTap: () => onMove(CrateDirection.down)),
    ]);
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: ChunkyButton(
      onPressed: onTap,
      color: _palette.surface,
      edgeColor: _palette.edge,
      depth: 3,
      radius: 12,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: 29, color: _palette.accent),
    ),
  );
}
