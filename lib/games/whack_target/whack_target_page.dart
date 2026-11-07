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
  int _windowSerial = 0;
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
    _windowSerial = 0;
    _timer = Timer.periodic(Duration(milliseconds: _engine.windowMilliseconds), (_) {
      if (!mounted) return;
      final result = _engine.elapse();
      if (result == TargetAction.ignored) return;
      setState(() => _windowSerial++);
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
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration = reducedMotion ? Duration.zero
          : const Duration(milliseconds: 175);
      final side = min(constraints.maxWidth - 28,
        constraints.maxHeight - (reported || _engine.isFailed ? 340 : 220))
        .clamp(215.0, 390.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'HITS', value: '${_engine.hits}/${_engine.goal}', palette: _palette),
                StatChip(label: 'MISSES', value: '${_engine.misses}/3', palette: _palette),
              ])),
          const SizedBox(height: 11),
          if (!reported && !_engine.isFailed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(
                label: 'Time until the target moves',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: reducedMotion
                      ? const LinearProgressIndicator(
                          value: 1,
                          minHeight: 7,
                          backgroundColor: Color(0xFFF3D5CF),
                          color: Color(0xFFEA7B76),
                        )
                      : TweenAnimationBuilder<double>(
                          key: ValueKey('whack-window-$_windowSerial'),
                          tween: Tween(begin: 1, end: 0),
                          duration: Duration(
                            milliseconds: _engine.windowMilliseconds),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFF3D5CF),
                            color: _palette.accent,
                          ),
                        ),
                ),
              ),
            ),
          const SizedBox(height: 11),
          Container(
            width: side, height: side,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFEED9D4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2C6BF)),
              boxShadow: const [
                BoxShadow(color: Color(0x285B4144),
                  blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
              ),
              itemBuilder: (context, cell) {
                final target = cell == _engine.target;
                final hit = target && _engine.hitThisWindow;
                return Semantics(
                  key: ValueKey('whack-cell-$cell'),
                  button: true,
                  enabled: !reported && !_engine.isFailed,
                  label: target ? (hit ? 'Target hit in spot ${cell + 1}'
                      : 'Target in spot ${cell + 1}')
                      : 'Empty spot ${cell + 1}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: reported || _engine.isFailed
                          ? null : () => _tap(cell),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedScale(
                        duration: duration,
                        curve: Curves.easeOutBack,
                        scale: target ? (hit ? .95 : 1.035) : .98,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: target
                                  ? hit
                                      ? const [
                                          Color(0xFFCEF4CC),
                                          Color(0xFF89C99A),
                                        ]
                                      : const [
                                          Color(0xFFFFF0B7),
                                          Color(0xFFFFC566),
                                        ]
                                  : const [
                                      Color(0xFFFFF7F2),
                                      Color(0xFFF3DBD7),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: target
                                  ? hit ? const Color(0xFF65A97C)
                                      : const Color(0xFFEAB65B)
                                  : const Color(0xFFE2C9C3),
                              width: target ? 2 : 1,
                            ),
                            boxShadow: target ? [
                              BoxShadow(
                                color: hit ? const Color(0x5565B97A)
                                    : const Color(0x66EAB65B),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ] : null,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: duration,
                              child: target
                                  ? Icon(
                                      hit ? Icons.check_rounded
                                          : Icons.pets_rounded,
                                      key: ValueKey('whack-icon-$cell-$hit'),
                                      size: side / 9,
                                      color: hit
                                          ? const Color(0xFF397748)
                                          : const Color(0xFF9A6923),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('whack-empty')),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
