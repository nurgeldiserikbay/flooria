import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'target_sum_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFE2F3EA),
  surface: Color(0xFFFBFFFC),
  ink: Color(0xFF15372B),
  muted: Color(0xFF5F8576),
  accent: Color(0xFF1E9A6A),
  edge: Color(0xFF15372B),
);
const _tileColor = Color(0xFFFFFFFF);
const _slotEmpty = Color(0xFFCFE7DA);

Widget buildTargetSumPage(BuildContext context, GameLaunch launch) =>
    TargetSumPage(launch: launch);

class TargetSumPage extends StatefulWidget {
  const TargetSumPage({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<TargetSumPage> createState() => _TargetSumPageState();
}

class _TargetSumPageState extends State<TargetSumPage>
    with LevelFlow<TargetSumPage> {
  late TargetSumEngine _engine;
  int _shakes = 0;
  String _feedback = 'PICK NUMBERS THAT ADD UP TO THE TARGET';
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
    _engine = TargetSumEngine.forLevel(level);
    _shakes = 0;
    _feedback = 'PICK NUMBERS THAT ADD UP TO THE TARGET';
  }

  void _later(Duration delay, VoidCallback action) {
    final generation = _generation;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!mounted || generation != _generation) return;
      action();
    });
  }

  void _toggle(int tile) {
    final result = _engine.toggle(tile);
    switch (result) {
      case SumResult.ignored:
        return;
      case SumResult.placed:
      case SumResult.removed:
        HapticFeedback.selectionClick();
        setState(() {
          _feedback = result == SumResult.removed
              ? 'NUMBER REMOVED · ${_engine.currentRound.picks - _engine.slots.length} SPOTS LEFT'
              : '${_engine.slots.length} OF ${_engine.currentRound.picks} NUMBERS SELECTED';
        });
      case SumResult.incorrect:
        HapticFeedback.heavyImpact();
        setState(() {
          _shakes++;
          _feedback = 'NOT THE TARGET · TRY A DIFFERENT COMBINATION';
        });
        _later(const Duration(milliseconds: 650),
          () => setState(() {
            _engine.clearWrong();
            _feedback = 'TRY AGAIN · PICK ${_engine.currentRound.picks} NUMBERS';
          }));
      case SumResult.correct:
      case SumResult.completed:
        HapticFeedback.lightImpact();
        setState(() => _feedback = 'CORRECT TOTAL · GREAT WORK!');
        _later(const Duration(milliseconds: 600), () {
          setState(() {
            _engine.advance();
            if (!_engine.isCompleted) {
              _feedback = 'NEXT ROUND · MAKE ${_engine.currentRound.target}';
            }
          });
          if (_engine.isCompleted) {
            HapticFeedback.mediumImpact();
            reportWin(score: _engine.score,
              metrics: {'math': _engine.mathMetric});
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _engine.isCompleted;
    final round = _engine.currentRound;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GameScaffold(
      palette: _palette,
      title: 'Target Sum',
      level: level,
      titleKey: const ValueKey('sum-title'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(children: [
          SegmentBar(
            total: _engine.rounds.length,
            done: _engine.roundIndex +
                (_engine.phase == SumPhase.solved ? 1 : 0),
            palette: _palette,
          ),
          const SizedBox(height: 14),
          _TargetHeader(engine: _engine, shakes: _shakes, reduceMotion: reduceMotion),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final columns = round.values.length == 8 ? 4 : 3;
              final rowsCount = (round.values.length / columns).ceil();
              final tile = min(
                (box.maxWidth - (columns - 1) * 10) / columns,
                (box.maxHeight - 20 - (rowsCount - 1) * 10) / rowsCount,
              ).clamp(52.0, 96.0).toDouble();
              return Center(
                child: SizedBox(
                  width: tile * columns + (columns - 1) * 10,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < round.values.length; i++)
                        _NumberTile(
                          key: ValueKey('sum-tile-${_engine.roundIndex}-$i'),
                          value: round.values[i],
                          side: tile,
                          used: _engine.isUsed(i),
                          reduceMotion: reduceMotion,
                          onTap: done ? null : () => _toggle(i),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
            child: done
                ? LevelResultPanel(
                    palette: _palette,
                    launch: launch,
                    level: level,
                    stars: _engine.stars,
                    detail: _engine.mistakes == 0
                        ? 'Every total right first time'
                        : '${_engine.mistakes} wrong totals',
                    onNext: nextLevel,
                    onReplay: replayLevel,
                  )
                : HintLine(_feedback, palette: _palette),
          ),
        ]),
      ),
    );
  }
}

class _TargetHeader extends StatelessWidget {
  const _TargetHeader({required this.engine, required this.shakes,
    required this.reduceMotion});
  final TargetSumEngine engine;
  final int shakes;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final round = engine.currentRound;
    final phase = engine.phase;
    final slotColor = switch (phase) {
      SumPhase.wrong => _palette.danger,
      SumPhase.solved => _palette.success,
      SumPhase.picking => _palette.edge,
    };
    return Semantics(
      key: const ValueKey('sum-target-state'),
      label: 'Make ${round.target} with ${round.picks} numbers. '
          '${engine.slots.length} selected. '
          '${engine.showRunningTotal ? 'Current sum ${engine.runningTotal}. ' : ''}'
          'Round ${engine.roundIndex + 1} of ${engine.rounds.length}. '
          '${switch (phase) { SumPhase.picking => 'Choose numbers', SumPhase.wrong => 'Incorrect total', SumPhase.solved => 'Correct total' }}',
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _palette.ink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _palette.edge, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF9CC9B3), offset: Offset(0, 5))],
      ),
      child: Column(children: [
        Text('MAKE', style: TextStyle(
          color: Colors.white.withValues(alpha: .6), fontSize: 11,
          fontWeight: FontWeight.w900, letterSpacing: 2)),
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
          child: Text('${round.target}',
            key: ValueKey('sum-target-${engine.roundIndex}'),
            style: const TextStyle(color: Colors.white, fontSize: 44,
              fontWeight: FontWeight.w900, height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 8),
        Shake(
          trigger: shakes,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < round.picks; i++) ...[
              if (i > 0) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('+', style: TextStyle(
                  color: Colors.white.withValues(alpha: .6),
                  fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _Slot(
                reduceMotion: reduceMotion,
                value: i < engine.slots.length
                    ? round.values[engine.slots[i]] : null,
                border: slotColor,
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('=', style: TextStyle(
                color: Colors.white.withValues(alpha: .6),
                fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Text(
              engine.showRunningTotal || phase != SumPhase.picking
                  ? '${engine.runningTotal}' : '?',
              key: const ValueKey('sum-running'),
              style: TextStyle(
                color: phase == SumPhase.wrong ? const Color(0xFFFF9AA2)
                    : phase == SumPhase.solved ? const Color(0xFF8BF0C4)
                    : Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ])),
        ),
      ]),
    ));
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.value, required this.border,
    required this.reduceMotion});
  final int? value;
  final Color border;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
    width: 46,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: value == null ? Colors.white.withValues(alpha: .08) : _slotEmpty,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: value == null ? Colors.white.withValues(alpha: .35) : border,
        width: 2),
    ),
    child: value == null
        ? null
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: .4, end: 1),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Text('$value', style: TextStyle(color: _palette.ink,
              fontSize: 18, fontWeight: FontWeight.w900)),
          ),
  );
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({super.key, required this.value, required this.side,
    required this.used, required this.onTap, required this.reduceMotion});

  final int value;
  final double side;
  final bool used;
  final bool reduceMotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Number $value, ${used ? 'selected, tap to remove' : 'tap to select'}',
    button: true,
    enabled: onTap != null,
    child: SizedBox(
    width: side,
    height: side,
    child: AnimatedOpacity(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
      opacity: used ? .52 : 1,
      child: ChunkyButton(
        onPressed: onTap,
        color: used ? _slotEmpty : _tileColor,
        edgeColor: _palette.edge,
        radius: 16,
        padding: EdgeInsets.zero,
        semanticLabel: '$value',
        child: Text('$value', style: TextStyle(color: _palette.ink,
          fontSize: side * .36, fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    ),
  ));
}
