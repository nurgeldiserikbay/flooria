import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'shape_turn_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFBEEDD),
  surface: Color(0xFFFFFAF3),
  ink: Color(0xFF3A2A20),
  muted: Color(0xFF977F6C),
  accent: Color(0xFFE0663C),
  edge: Color(0xFF3A2A20),
);
const _shapeFill = Color(0xFFE0663C);
const _shapeCore = Color(0xFFF59A6E);

Widget buildShapeTurnPage(BuildContext context, GameLaunch launch) =>
    ShapeTurnPage(launch: launch);

class ShapeTurnPage extends StatefulWidget {
  const ShapeTurnPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<ShapeTurnPage> createState() => _ShapeTurnPageState();
}

class _ShapeTurnPageState extends State<ShapeTurnPage>
    with LevelFlow<ShapeTurnPage> {
  late ShapeTurnEngine _engine;
  int _attempt = 0;
  int _generation = 0;
  Timer? _timer;

  @override
  GameLaunch get launch => widget.launch;

  @override
  void initState() {
    super.initState();
    resetLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void resetLevel() {
    _timer?.cancel();
    _generation++;
    // A retry gets fresh shapes so the answer cannot simply be remembered.
    _engine = ShapeTurnEngine.forLevel(level,
      seed: _attempt == 0 ? null : level * 3001 + 7 + _attempt * 7919);
  }

  void _retry() {
    _attempt++;
    replayLevel();
  }

  void _answer(int option) {
    final result = _engine.answer(option);
    if (result == ShapeAnswer.ignored) return;
    final correct = _engine.currentRound.options[option].correct;
    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {});
    if (result == ShapeAnswer.failed) return;
    final generation = _generation;
    _timer = Timer(Duration(milliseconds: correct ? 650 : 1100), () {
      if (!mounted || generation != _generation) return;
      setState(_engine.advance);
      if (_engine.isCompleted) {
        HapticFeedback.mediumImpact();
        reportWin(score: _engine.score,
          metrics: {'spatial': _engine.spatialMetric});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _engine.currentRound;
    final done = _engine.isCompleted;
    final failed = _engine.isFailed;
    final chosen = _engine.chosen;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GameScaffold(
      palette: _palette,
      title: 'Shape Turn',
      level: level,
      titleKey: const ValueKey('shape-title'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          SegmentBar(
            total: _engine.rounds.length,
            done: _engine.roundIndex + (chosen != null ? 1 : 0),
            failed: _engine.missedRounds,
            palette: _palette,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text('WHICH ONE IS ONLY TURNED?',
                style: TextStyle(color: _palette.ink, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            ),
            StatChip(label: 'MISSES',
              value: '${_engine.mistakes}/${_engine.allowedMistakes}',
              valueKey: const ValueKey('shape-misses'), palette: _palette),
          ]),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final optionSide = min((box.maxWidth - 12) / 2,
                (box.maxHeight - 24) * .32).clamp(90.0, 190.0).toDouble();
              final targetSide = (optionSide * 1.05).clamp(90.0, 200.0).toDouble();
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TargetCard(round: round, side: targetSide,
                    span: _span(round), reducedMotion: reducedMotion),
                  SizedBox(
                    width: optionSide * 2 + 12,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < round.options.length; i++)
                          _OptionCard(
                            key: ValueKey('shape-option-${_engine.roundIndex}-$i'),
                            option: round.options[i],
                            side: optionSide,
                            span: _span(round),
                            reducedMotion: reducedMotion,
                            index: i,
                            state: chosen == null
                                ? _CardState.idle
                                : round.options[i].correct
                                    ? _CardState.right
                                    : chosen == i
                                        ? _CardState.wrong
                                        : _CardState.faded,
                            onTap: done || failed ? null : () => _answer(i),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
          AnimatedSwitcher(
            duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
            child: done
                ? LevelResultPanel(
                    palette: _palette,
                    launch: launch,
                    level: level,
                    stars: _engine.stars,
                    detail: '${_engine.correct} of ${_engine.rounds.length} shapes matched',
                    onNext: nextLevel,
                    onReplay: replayLevel,
                  )
                : failed
                    ? RetryPanel(
                        palette: _palette,
                        title: 'TOO MANY MIRRORS',
                        detail: 'A mirror image looks close but never fits by turning.',
                        onRetry: _retry,
                      )
                    : const SizedBox(height: 8),
          ),
        ]),
      ),
    );
  }
}

/// Largest bounding side in a round, so every card draws equal-size cells
/// and size gives nothing away.
int _span(ShapeRound round) => [
  for (final shape in [round.target, for (final o in round.options) o.base])
    ...[shape.map((c) => c.$1).reduce(max) + 1,
        shape.map((c) => c.$2).reduce(max) + 1],
].reduce(max);

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.round, required this.side,
    required this.span, required this.reducedMotion});
  final ShapeRound round;
  final double side;
  final int span;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        key: const ValueKey('shape-target-state'),
        label: 'Reference shape, ${round.target.length} square cells',
        child: Container(
        width: side,
        height: side * .82,
        padding: EdgeInsets.all(side * .1),
        decoration: BoxDecoration(
          color: _palette.ink,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _palette.edge, width: 2),
          boxShadow: const [BoxShadow(color: Color(0xFFC8A98C), offset: Offset(0, 5))],
        ),
        child: AnimatedSwitcher(
          duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
          child: CustomPaint(
            key: ValueKey(Shapes.key(round.target)),
            painter: _ShapePainter(round.target, span: span,
              fill: const Color(0xFFFFE2CC), core: Colors.white,
              stroke: _palette.ink),
            child: const SizedBox.expand(),
          ),
        ),
      )),
    ],
  );
}

enum _CardState { idle, right, wrong, faded }

class _OptionCard extends StatelessWidget {
  const _OptionCard({super.key, required this.option, required this.side,
    required this.span, required this.state, required this.onTap,
    required this.reducedMotion, required this.index});

  final ShapeOption option;
  final double side;
  final int span;
  final _CardState state;
  final VoidCallback? onTap;
  final bool reducedMotion;
  final int index;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      _CardState.right => _palette.success,
      _CardState.wrong => _palette.danger,
      _ => _palette.edge,
    };
    // A correct pick turns back upright to show it matches the target.
    final turns = state == _CardState.right
        ? (option.turns <= 2 ? 0.0 : 1.0)
        : option.turns / 4;
    final feedback = switch (state) {
      _CardState.idle => 'Select option',
      _CardState.right => 'Correct matching rotation',
      _CardState.wrong => 'Incorrect selection',
      _CardState.faded => 'Not selected',
    };
    return Semantics(
      key: ValueKey('shape-option-state-$index'),
      button: true,
      enabled: onTap != null,
      label: 'Option ${index + 1}, $feedback',
      child: AnimatedOpacity(
      duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 200),
      opacity: state == _CardState.faded ? .45 : 1,
      child: SizedBox(
        width: side,
        height: side,
        child: ChunkyButton(
          onPressed: onTap,
          color: state == _CardState.right
              ? const Color(0xFFE6F6EC)
              : state == _CardState.wrong
                  ? const Color(0xFFFDE5E3)
                  : _palette.surface,
          edgeColor: border,
          borderColor: border,
          radius: 18,
          padding: EdgeInsets.all(side * .16),
          child: AnimatedRotation(
            turns: turns,
            duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeInOutBack,
            child: CustomPaint(
              painter: _ShapePainter(option.base, span: span,
                fill: _shapeFill, core: _shapeCore, stroke: _palette.ink),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
  }
}

/// Draws a polyomino centred in a square, so rotating the canvas keeps it
/// inside the card. Cell decoration is rotation-symmetric on purpose: any
/// directional shading would reveal how far an option was turned.
class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.cells, {required this.span, required this.fill,
    required this.core, required this.stroke});

  final List<Cell> cells;
  final int span;
  final Color fill;
  final Color core;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = cells.map((c) => c.$1).reduce(max) + 1;
    final columns = cells.map((c) => c.$2).reduce(max) + 1;
    final unit = min(size.width, size.height) / max(span, 3);
    final origin = Offset(
      (size.width - columns * unit) / 2,
      (size.height - rows * unit) / 2,
    );
    final radius = Radius.circular(unit * .16);
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, unit * .07);
    for (final (r, c) in cells) {
      final rect = Rect.fromLTWH(origin.dx + c * unit, origin.dy + r * unit,
        unit, unit).deflate(unit * .045);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(rrect, Paint()..color = fill);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: rect.width * .34,
          height: rect.height * .34),
        Radius.circular(unit * .06)), Paint()..color = core);
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.cells != cells || old.fill != fill || old.span != span;
}
