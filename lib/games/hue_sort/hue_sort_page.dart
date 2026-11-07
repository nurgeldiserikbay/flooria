import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'hue_sort_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF6F1E9),
  surface: Color(0xFFFFFCF7),
  ink: Color(0xFF2A2420),
  muted: Color(0xFF8B7F73),
  accent: Color(0xFF2A2420),
  edge: Color(0xFF2A2420),
);

Widget buildHueSortPage(BuildContext context, GameLaunch launch) =>
    HueSortPage(launch: launch);

class HueSortPage extends StatefulWidget {
  const HueSortPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<HueSortPage> createState() => _HueSortPageState();
}

class _HueSortPageState extends State<HueSortPage> with LevelFlow<HueSortPage> {
  late HueSortEngine _engine;
  int? _selected;
  int _nudge = 0;

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void resetLevel() {
    _engine = HueSortEngine.forLevel(level);
    _selected = null;
    _nudge = 0;
  }

  void _tap(int position) {
    if (_engine.isCompleted) return;
    if (_engine.isFixed(position)) {
      HapticFeedback.selectionClick();
      setState(() => _nudge++);
      return;
    }
    final selected = _selected;
    if (selected == null || selected == position) {
      HapticFeedback.selectionClick();
      setState(() => _selected = selected == position ? null : position);
      return;
    }
    final result = _engine.swap(selected, position);
    if (result == HueSwapResult.ignored) return;
    setState(() => _selected = null);
    if (result == HueSwapResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'perception': _engine.perceptionMetric});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _engine.isCompleted;
    return GameScaffold(
      palette: _palette,
      title: 'Hue Sort',
      level: level,
      titleKey: const ValueKey('hue-title'),
      actions: [
        ChunkyIconButton(
          icon: Icons.restart_alt_rounded,
          tooltip: 'Restart',
          palette: _palette,
          onPressed: done ? null : replayLevel,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text('RESTORE THE GRADIENT',
                style: TextStyle(color: _palette.ink, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            StatChip(label: 'SWAPS', value: '${_engine.swaps}',
              valueKey: const ValueKey('hue-swaps'), palette: _palette),
          ]),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final cell = min(
                (box.maxWidth - 12) / _engine.columns,
                (box.maxHeight - 24) / _engine.rows,
              ).clamp(30.0, 84.0).toDouble();
              return Center(
                child: _HueBoard(
                  engine: _engine,
                  cell: cell,
                  selected: _selected,
                  nudge: _nudge,
                  onTap: _tap,
                ),
              );
            }),
          ),
          AnimatedSwitcher(
            duration: MediaQuery.maybeOf(context)?.disableAnimations == true
                ? Duration.zero : const Duration(milliseconds: 220),
            child: done
                ? LevelResultPanel(
                    palette: _palette,
                    launch: launch,
                    level: level,
                    stars: _engine.stars,
                    detail: '${_engine.swaps} swaps · fewest possible ${_engine.minSwaps}',
                    onNext: nextLevel,
                    onReplay: replayLevel,
                  )
                : HintLine('DOTS ARE FIXED  ·  TAP TWO TO SWAP',
                    palette: _palette,
                    leading: Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: _palette.ink,
                        shape: BoxShape.circle)),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _HueBoard extends StatelessWidget {
  const _HueBoard({required this.engine, required this.cell,
    required this.selected, required this.nudge, required this.onTap});

  final HueSortEngine engine;
  final double cell;
  final int? selected;
  final int nudge;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final done = engine.isCompleted;
    final motion = MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero : const Duration(milliseconds: 240);
    final boardMotion = MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero : const Duration(milliseconds: 420);
    final positions = <int, int>{
      for (var p = 0; p < engine.cellCount; p++) engine.tileAt(p): p,
    };
    final gap = done ? 0.0 : 4.0;
    return Shake(
      trigger: nudge,
      child: AnimatedContainer(
        duration: boardMotion,
        curve: Curves.easeOutCubic,
        // Padding 4 and a 2px border on each side.
        width: cell * engine.columns + 12,
        height: cell * engine.rows + 12,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _palette.surface,
          borderRadius: BorderRadius.circular(done ? 12 : 16),
          border: Border.all(color: const Color(0xFFD8D0C6), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x282A2420),
              blurRadius: 16, offset: Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(done ? 8 : 10),
          child: Stack(children: [
            for (var tile = 0; tile < engine.cellCount; tile++)
              _positioned(tile, positions[tile]!, gap, done,
                motion, boardMotion),
          ]),
        ),
      ),
    );
  }

  Widget _positioned(int tile, int position, double gap,
      bool done, Duration motion, Duration boardMotion) {
    final row = position ~/ engine.columns;
    final column = position % engine.columns;
    final isSelected = selected == position;
    final fixed = engine.isFixed(position);
    final color = Color(engine.colors[tile]);
    final dark = color.computeLuminance() < .35;
    return AnimatedPositioned(
      key: ValueKey('hue-tile-$tile'),
      duration: motion,
      curve: Curves.easeInOutCubic,
      left: column * cell,
      top: row * cell,
      width: cell,
      height: cell,
      child: Semantics(
        key: ValueKey('hue-tile-state-$position'),
        button: true,
        enabled: !done && !fixed,
        selected: isSelected,
        label: 'Color tile in row ${row + 1}, column ${column + 1}'
            '${fixed ? ', fixed reference' : ''}'
            '${isSelected ? ', selected' : ''}',
        child: GestureDetector(
          key: ValueKey('hue-cell-$position'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(position),
          child: AnimatedPadding(
            duration: boardMotion,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(gap / 2),
            child: AnimatedScale(
              scale: isSelected ? .86 : 1,
              duration: motion,
              child: AnimatedContainer(
                duration: boardMotion,
                curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(done ? 0 : 6),
                border: isSelected
                    ? Border.all(color: dark ? Colors.white : _palette.ink, width: 3)
                    : null,
              ),
              child: fixed && !done
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dark ? Colors.white : _palette.ink,
                        ),
                      ),
                    )
                  : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
