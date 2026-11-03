import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'whack_target_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF0E9), surface: Colors.white, ink: Color(0xFF5B4144),
  muted: Color(0xFFA17E82), accent: Color(0xFFEA7B76), edge: Color(0xFF5B4144),
);

Widget buildWhackTargetPage(BuildContext context, GameLaunch launch) =>
    WhackTargetPage(launch: launch);

class WhackTargetPage extends StatefulWidget {
  const WhackTargetPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<WhackTargetPage> createState() => _WhackTargetPageState();
}

class _WhackTargetPageState extends State<WhackTargetPage> with LevelFlow<WhackTargetPage> {
  late WhackTargetEngine _engine;
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
    _engine = WhackTargetEngine.forLevel(level);
    _timer = Timer.periodic(Duration(milliseconds: _engine.windowMilliseconds), (_) {
      if (!mounted) return;
      final result = _engine.elapse();
      if (result == TargetAction.ignored) return;
      setState(() {});
      if (result == TargetAction.failed) {
        _timer?.cancel();
        HapticFeedback.vibrate();
      } else if (result == TargetAction.missed) {
        HapticFeedback.selectionClick();
      }
    });
  }

  void _tap(int cell) {
    final result = _engine.tap(cell);
    if (result == TargetAction.ignored) return;
    setState(() {});
    if (result == TargetAction.completed) {
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Whack the Target',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 250 : 180))
        .clamp(250.0, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'HITS', value: '${_engine.hits}/${_engine.goal}', palette: _palette),
                StatChip(label: 'MISSES', value: '${_engine.misses}/3', palette: _palette),
              ])),
          const SizedBox(height: 16),
          Container(width: side, height: side, padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xFFE6CEC9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9),
              itemBuilder: (context, cell) {
                final target = cell == _engine.target;
                final hit = target && _engine.hitThisWindow;
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported || _engine.isFailed
                      ? null : () => _tap(cell),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: target ? hit ? const Color(0xFF9ED9A8)
                          : const Color(0xFFFFD36D) : const Color(0xFFF8E8E2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: target ? _palette.edge
                          : const Color(0xFFDCC4BF), width: target ? 2 : 1.5),
                        boxShadow: target ? const [BoxShadow(color: Color(0x445B4144),
                          offset: Offset(0, 4))] : null,
                      ),
                      child: target ? Icon(hit ? Icons.check_rounded : Icons.pets_rounded,
                        size: side / 9, color: hit ? const Color(0xFF397748)
                          : const Color(0xFF9A6923)) : null,
                    )),
                );
              },
            )),
          const SizedBox(height: 16),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.misses == 0 ? 3 : _engine.misses == 1 ? 2 : 1,
                detail: 'You hit every moving target.',
                onReplay: replayLevel, onNext: nextLevel))
          else if (_engine.isFailed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: RetryPanel(palette: _palette, title: 'TARGET GOT AWAY',
                detail: 'Stay ready and tap before it moves.', onRetry: replayLevel))
          else
            const HintLine('TAP THE GLOWING TARGET BEFORE IT MOVES', palette: _palette),
        ]));
    }),
  );
}
