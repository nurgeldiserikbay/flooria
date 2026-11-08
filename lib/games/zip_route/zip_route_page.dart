import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'zip_route_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF3F8), surface: Colors.white, ink: Color(0xFF3B5264),
  muted: Color(0xFF7F94A2), accent: Color(0xFF4B9BC7), edge: Color(0xFF3B5264),
);

Widget buildZipRoutePage(BuildContext context, GameLaunch launch) =>
    ZipRoutePage(launch: launch);

class ZipRoutePage extends StatefulWidget {
  const ZipRoutePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<ZipRoutePage> createState() => _ZipRoutePageState();
}

class _ZipRoutePageState extends State<ZipRoutePage> with LevelFlow<ZipRoutePage> {
  late ZipRouteEngine _engine;
  String _hint = 'FILL EVERY CELL · FOLLOW THE NUMBERED DOTS';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = ZipRouteEngine.forLevel(level);
    _hint = 'FILL EVERY CELL · FOLLOW THE NUMBERED DOTS';
  }

  bool _canEnter(int cell) {
    if (reported || _engine.isCompleted || _engine.path.contains(cell)) return false;
    final side = _engine.side;
    final current = _engine.position;
    if ((cell ~/ side - current ~/ side).abs() +
        (cell % side - current % side).abs() != 1) return false;
    final checkpoint = _engine.checkpoints[cell];
    return checkpoint == null || checkpoint == _engine.nextCheckpoint;
  }

  void _enter(int cell) {
    final result = _engine.enter(cell);
    if (result == ZipMove.ignored || result == ZipMove.blocked) {
      if (result == ZipMove.blocked) {
        setState(() => _hint = 'CHOOSE A GLOWING NEIGHBOR · FOLLOW DOTS IN ORDER');
        HapticFeedback.selectionClick();
      }
      return;
    }
    setState(() => _hint = 'KEEP GOING · FILL THE WHOLE GRID');
    if (result == ZipMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GameScaffold(
    palette: _palette,
    title: 'Zip Route',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final board = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported ? 245 : 170)).clamp(245.0, 430.0).toDouble();
      final visited = _engine.path.toSet();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'FILLED', value: '${_engine.filledCount}/${_engine.side * _engine.side}', palette: _palette),
                StatChip(label: 'NEXT DOT', value: '${_engine.nextCheckpoint}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Container(width: board, height: board, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFC9D9E2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.side * _engine.side,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _engine.side, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, cell) {
                final checkpoint = _engine.checkpoints[cell];
                final current = cell == _engine.position;
                final filled = visited.contains(cell);
                final available = _canEnter(cell);
                final row = cell ~/ _engine.side + 1;
                final col = cell % _engine.side + 1;
                return Semantics(
                  key: ValueKey('zip-cell-state-$cell'),
                  button: true,
                  enabled: !reported,
                  label: 'Row $row, column $col, '
                    '${checkpoint == null ? 'empty' : 'checkpoint $checkpoint'}, '
                    '${current ? 'current position' : filled ? 'visited' : available ? 'available next step' : 'not available'}',
                  child: Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _enter(cell),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(color: current
                        ? const Color(0xFF76BDE2) : filled ? const Color(0xFF8DD0B3)
                        : available ? const Color(0xFFE1F4FF) : const Color(0xFFF7FBFD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: current ? _palette.edge
                          : available ? const Color(0xFF4B9BC7)
                          : const Color(0xFFB8CDD8), width: current || available ? 2 : 1)),
                      child: Center(child: checkpoint != null
                        ? Text('$checkpoint', style: TextStyle(color: current
                            ? Colors.white : _palette.ink,
                          fontSize: board / _engine.side * .42,
                          fontWeight: FontWeight.w900))
                        : current ? const Icon(Icons.circle, size: 10, color: Colors.white)
                          : null),
                    )),
                ));
              },
            )),
          const SizedBox(height: 14),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: 3, detail: 'Connected every cell in order.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            HintLine(_hint, palette: _palette),
        ]));
    }),
  );
  }
}
