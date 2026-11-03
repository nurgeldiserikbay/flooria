import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'gravity_shift_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF0EEFF), surface: Colors.white, ink: Color(0xFF4D4B70),
  muted: Color(0xFF8583A8), accent: Color(0xFF8279D8), edge: Color(0xFF4D4B70),
);

Widget buildGravityShiftPage(BuildContext context, GameLaunch launch) =>
    GravityShiftPage(launch: launch);

class GravityShiftPage extends StatefulWidget {
  const GravityShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<GravityShiftPage> createState() => _GravityShiftPageState();
}

class _GravityShiftPageState extends State<GravityShiftPage> with LevelFlow<GravityShiftPage> {
  late GravityShiftEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = GravityShiftEngine.forLevel(level);

  void _tilt(GravityDirection direction) {
    final result = _engine.tilt(direction);
    if (result == GravityMove.ignored || result == GravityMove.blocked) {
      HapticFeedback.selectionClick();
      return;
    }
    setState(() {});
    if (result == GravityMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Gravity Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 32,
        constraints.maxHeight - (reported || _engine.isFailed ? 300 : 235))
        .clamp(230.0, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'MOVES LEFT', value: '${_engine.movesLeft}', palette: _palette),
              StatChip(label: 'WALLS', value: '${_engine.walls.length}', palette: _palette),
            ])),
          const SizedBox(height: 14),
          Container(width: side, height: side, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFD8D7EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: GravityShiftEngine.side * GravityShiftEngine.side,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: GravityShiftEngine.side, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemBuilder: (context, cell) {
                final wall = _engine.walls.contains(cell);
                final ball = _engine.ball == cell;
                final goal = _engine.goal == cell;
                return AnimatedContainer(duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: wall ? const Color(0xFF69688E) : const Color(0xFFF7F6FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: wall ? _palette.edge : const Color(0xFFDDDCF0))),
                  child: Center(child: ball
                    ? Container(width: side / 11, height: side / 11,
                        decoration: BoxDecoration(color: const Color(0xFF78BDE0), shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x8878BDE0), blurRadius: 7)]))
                    : goal ? const Icon(Icons.flag_rounded, color: Color(0xFF67AE83))
                    : wall ? const Icon(Icons.square_rounded, size: 12, color: Color(0xFF9291B1)) : null),
                );
              },
            )),
          const SizedBox(height: 10),
          if (!reported && !_engine.isFailed)
            Column(mainAxisSize: MainAxisSize.min, children: [
              _DirectionButton(icon: Icons.keyboard_arrow_up_rounded, onTap: () => _tilt(GravityDirection.up)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _DirectionButton(icon: Icons.keyboard_arrow_left_rounded, onTap: () => _tilt(GravityDirection.left)),
                const SizedBox(width: 52),
                _DirectionButton(icon: Icons.keyboard_arrow_right_rounded, onTap: () => _tilt(GravityDirection.right)),
              ]),
              _DirectionButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => _tilt(GravityDirection.down)),
            ]),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 6 ? 3 : _engine.moves <= 9 ? 2 : 1,
                detail: 'Rolled the core to the exit.', onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'MOVES USED',
                detail: 'Each tilt rolls the core until a wall stops it.', onRetry: replayLevel))
          else
            const HintLine('TILT GRAVITY · USE WALLS TO CHANGE COURSE', palette: _palette),
        ]));
    }),
  );
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: 46, height: 41,
    child: ChunkyButton(onPressed: onTap, color: Colors.white, edgeColor: _palette.edge,
      depth: 3, radius: 10, padding: EdgeInsets.zero,
      child: Icon(icon, color: _palette.ink, size: 27)));
}
