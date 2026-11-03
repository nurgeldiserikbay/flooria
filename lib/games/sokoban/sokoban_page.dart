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
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = SokobanEngine.forLevel(level);

  void _move(CrateDirection direction) {
    final result = _engine.move(direction);
    if (result == SokobanMove.ignored || result == SokobanMove.blocked) {
      if (result == SokobanMove.blocked) HapticFeedback.selectionClick();
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
          Container(width: side, height: side, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFDACBAF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: SokobanEngine.side * SokobanEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: SokobanEngine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) => _Cell(
                wall: _engine.isWall(cell), crate: _engine.crates.contains(cell),
                goal: _engine.goals.contains(cell), player: _engine.player == cell),
            )),
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
  const _Cell({required this.wall, required this.crate, required this.goal,
    required this.player});
  final bool wall, crate, goal, player;
  @override
  Widget build(BuildContext context) {
    final color = wall ? const Color(0xFF8D7963)
      : crate && goal ? const Color(0xFF8AAF70)
      : crate ? const Color(0xFFC98945)
      : const Color(0xFFEDE6D9);
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5),
        border: Border.all(color: wall ? const Color(0xFF78654F) : const Color(0xFFD7CBB7))),
      child: Stack(alignment: Alignment.center, children: [
        if (goal) Icon(Icons.circle, size: 13, color: crate
          ? const Color(0xFF557B5B) : const Color(0xFFF0C35F)),
        if (crate) const Icon(Icons.inventory_2_rounded, size: 17, color: Color(0xFF684520)),
        if (player) const Icon(Icons.person_pin_circle_rounded, size: 20, color: Color(0xFF3F6A53)),
      ]),
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
  Widget build(BuildContext context) => SizedBox(width: 42, height: 36,
    child: IconButton(onPressed: onTap, padding: EdgeInsets.zero,
      icon: Icon(icon, size: 34, color: _palette.ink)));
}
