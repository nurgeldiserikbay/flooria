import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'synapse_link_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFF0F1530),
  surface: Color(0xFF1A2347),
  ink: Color(0xFFEAF0FF),
  muted: Color(0xFF8C98C4),
  accent: Color(0xFF4FD8BC),
  edge: Color(0xFF060A1C),
  onAccent: Color(0xFF07251F),
);
const _lit = Color(0xFF5CE6C8);
const _dim = Color(0xFF3A4877);
const _sourceColor = Color(0xFFFFCF5C);
const _tileBorder = Color(0xFF2A3666);

Widget buildSynapseLinkPage(BuildContext context, GameLaunch launch) =>
    SynapseLinkPage(launch: launch);

class SynapseLinkPage extends StatefulWidget {
  const SynapseLinkPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<SynapseLinkPage> createState() => _SynapseLinkPageState();
}

class _SynapseLinkPageState extends State<SynapseLinkPage>
    with LevelFlow<SynapseLinkPage> {
  late SynapseLinkEngine _engine;
  late List<int> _turns;

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void resetLevel() {
    _engine = SynapseLinkEngine.forLevel(level);
    // Visual turn counters only grow, so every animation runs clockwise.
    _turns = List<int>.generate(_engine.cellCount, _engine.rotationAt);
  }

  void _tap(int index) {
    final result = _engine.rotate(index);
    if (result == SynapseTapResult.ignored) {
      if (_engine.isLocked(index)) HapticFeedback.selectionClick();
      return;
    }
    setState(() => _turns[index]++);
    if (result == SynapseTapResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'logic': _engine.logicMetric});
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _lock(int index) {
    if (_engine.toggleLock(index)) {
      HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lit = _engine.litCells;
    final done = _engine.isCompleted;
    return GameScaffold(
      palette: _palette,
      title: 'Synapse Link',
      level: level,
      titleKey: const ValueKey('synapse-title'),
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
            StatChip(label: 'LINKED',
              value: '${lit.length}/${_engine.cellCount}',
              valueKey: const ValueKey('synapse-linked'),
              palette: _palette),
            const SizedBox(width: 8),
            Expanded(
              child: StatGroup(children: [
                StatChip(label: 'TURNS', value: '${_engine.moves}',
                  palette: _palette),
                StatChip(label: 'PAR', value: '${_engine.par}',
                  palette: _palette),
              ]),
            ),
          ]),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final cell = min(
                (box.maxWidth) / _engine.columns,
                (box.maxHeight - 16) / _engine.rows,
              ).clamp(36.0, 92.0).toDouble();
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C3C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: done ? _lit : _tileBorder, width: 2),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFF060A1C),
                        offset: Offset(0, 6)),
                      if (done) BoxShadow(color: _lit.withValues(alpha: .25),
                        blurRadius: 30, spreadRadius: 2),
                    ],
                  ),
                  child: SizedBox(
                    width: cell * _engine.columns - 12,
                    height: cell * _engine.rows - 12,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _engine.columns,
                        mainAxisExtent: (cell * _engine.rows - 12) / _engine.rows,
                      ),
                      itemCount: _engine.cellCount,
                      itemBuilder: (context, index) => _SynapseTile(
                        key: ValueKey('synapse-tile-$index'),
                        mask: _engine.solution[index],
                        turns: _turns[index],
                        lit: lit.contains(index),
                        source: index == _engine.source,
                        leaf: _engine.isLeaf(index),
                        locked: _engine.isLocked(index),
                        onTap: done ? null : () => _tap(index),
                        onLongPress: done ? null : () => _lock(index),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: done
                ? LevelResultPanel(
                    palette: _palette,
                    launch: launch,
                    level: level,
                    stars: _engine.stars,
                    detail: 'Network linked in ${_engine.moves} turns · par ${_engine.par}',
                    onNext: nextLevel,
                    onReplay: replayLevel,
                  )
                : HintLine('TAP TO TURN  ·  HOLD TO PIN', palette: _palette),
          ),
        ]),
      ),
    );
  }
}

class _SynapseTile extends StatelessWidget {
  const _SynapseTile({
    super.key,
    required this.mask,
    required this.turns,
    required this.lit,
    required this.source,
    required this.leaf,
    required this.locked,
    required this.onTap,
    required this.onLongPress,
  });

  final int mask;
  final int turns;
  final bool lit;
  final bool source;
  final bool leaf;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(2),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: locked ? const Color(0xFF222C55) : const Color(0xFF1A2347),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: locked ? _sourceColor.withValues(alpha: .7) : _tileBorder,
            width: 1.5),
        ),
        child: AnimatedRotation(
          turns: turns / 4,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: lit ? 1 : 0),
            duration: const Duration(milliseconds: 260),
            builder: (context, glow, _) => CustomPaint(
              painter: _LinkPainter(mask: mask, glow: glow, source: source,
                leaf: leaf),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LinkPainter extends CustomPainter {
  const _LinkPainter({required this.mask, required this.glow,
    required this.source, required this.leaf});

  final int mask;
  final double glow;
  final bool source;
  final bool leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final side = size.shortestSide;
    final color = Color.lerp(_dim, _lit, glow)!;
    final ends = <Offset>[
      if (mask & Links.north != 0) Offset(center.dx, 0),
      if (mask & Links.east != 0) Offset(size.width, center.dy),
      if (mask & Links.south != 0) Offset(center.dx, size.height),
      if (mask & Links.west != 0) Offset(0, center.dy),
    ];

    if (glow > 0) {
      final halo = Paint()
        ..color = _lit.withValues(alpha: .22 * glow)
        ..strokeWidth = side * .34
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (final end in ends) {
        canvas.drawLine(center, end, halo);
      }
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = side * .16
      ..strokeCap = StrokeCap.butt;
    for (final end in ends) {
      canvas.drawLine(center, end, line);
    }
    canvas.drawCircle(center, side * .08, Paint()..color = color);

    if (source) {
      canvas.drawCircle(center, side * .3,
        Paint()..color = _sourceColor.withValues(alpha: .22));
      canvas.drawCircle(center, side * .22, Paint()..color = _sourceColor);
      canvas.drawCircle(center, side * .22, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF0F1530));
      canvas.drawCircle(center, side * .08,
        Paint()..color = const Color(0xFF0F1530));
    } else if (leaf) {
      canvas.drawCircle(center, side * .2, Paint()..color = const Color(0xFF1A2347));
      canvas.drawCircle(center, side * .2, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * .07
        ..color = color);
      canvas.drawCircle(center, side * .07,
        Paint()..color = Color.lerp(_dim, Colors.white, glow)!);
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) => old.mask != mask ||
      old.glow != glow || old.source != source || old.leaf != leaf;
}
