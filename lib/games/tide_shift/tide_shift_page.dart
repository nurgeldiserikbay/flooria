import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'tide_shift_engine.dart';

const _palette = GamePalette(ground: Color(0xFFE8F8F6), surface: Colors.white, ink: Color(0xFF315E5D),
  muted: Color(0xFF769E9C), accent: Color(0xFF36A99C), edge: Color(0xFF315E5D));
Widget buildTideShiftPage(BuildContext context, GameLaunch launch) => TideShiftPage(launch: launch);

class TideShiftPage extends StatefulWidget {
  const TideShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<TideShiftPage> createState() => _TideShiftPageState();
}

class _TideShiftPageState extends State<TideShiftPage> with LevelFlow<TideShiftPage> {
  late TideShiftEngine _engine;
  int _blockedPulse = 0;
  String _feedback = 'LOW GROUND FLOODS AS THE TIDE RISES';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = TideShiftEngine.forLevel(level);
    _blockedPulse = 0;
    _feedback = 'LOW GROUND FLOODS AS THE TIDE RISES';
  }

  void _step(int dr, int dc) {
    final result = _engine.step(dr, dc);
    if (result == TideMove.ignored) return;
    if (result == TideMove.blocked) {
      HapticFeedback.selectionClick();
      setState(() {
        _blockedPulse++;
        _feedback = 'EDGE OF MAP · CHOOSE ANOTHER DIRECTION';
      });
      return;
    }
    setState(() {
      final standingHigh = _engine.heights[_engine.position] >= 4;
      _feedback = result == TideMove.flooded
          ? 'WATER REACHED YOU · TRY THE GREEN HIGH PATH'
          : result == TideMove.completed
              ? 'SAFE ARRIVAL · YOU BEAT THE TIDE!'
              : standingHigh
                  ? 'ON HIGH GROUND · KEEP MOVING TOWARD THE FLAG'
                  : 'LOW GROUND · WATCH THE RISING WATER';
    });
    if (result == TideMove.flooded) {
      HapticFeedback.heavyImpact();
    } else if (result == TideMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Tide Shift', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final motion = reduceMotion ? Duration.zero
          : const Duration(milliseconds: 210);
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 350 : 300)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'TIDE', value: _engine.tide.toString(), palette: _palette),
          Semantics(
            label: 'Tide level ${_engine.tide}',
            child: Row(children: [
              for (var i = 0; i < 4; i++)
                AnimatedScale(
                  scale: i < _engine.tide ? 1.12 : .94,
                  duration: motion,
                  child: Icon(Icons.water_drop_rounded, size: 17,
                    color: i < _engine.tide ? _palette.accent
                        : const Color(0xFFC9E6E1)),
                ),
            ]),
          ),
          StatChip(label: 'STEPS', value: _engine.moves.toString(), palette: _palette),
        ])),
        const SizedBox(height: 9),
        Semantics(
          key: const ValueKey('tide-board-state'),
          label: 'Tide level ${_engine.tide}. Player at row '
              '${_engine.position ~/ TideShiftEngine.side + 1}, '
              'column ${_engine.position % TideShiftEngine.side + 1}. '
              '${_engine.heights[_engine.position] >= 4 ? 'High ground' : 'Low ground'}. '
              '${_engine.moves} steps taken.',
          child: Container(
          width: side, height: side,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFCBEAE4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA5D6CE)),
            boxShadow: const [
              BoxShadow(color: Color(0x26315E5D),
                blurRadius: 15, offset: Offset(0, 5)),
            ],
          ),
          child: GridView.builder(
            key: const ValueKey('tide-board'),
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 36,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final height = _engine.heights[cell];
              final flooded = height < _engine.tide;
              final player = cell == _engine.position;
              return Semantics(
                key: ValueKey('tide-cell-$cell'),
                label: 'Row ${cell ~/ TideShiftEngine.side + 1}, '
                    'column ${cell % TideShiftEngine.side + 1}, '
                    '${flooded ? 'flooded' : height >= 4 ? 'high ground' : 'low ground'}'
                    '${player ? ', player' : ''}'
                    '${cell == _engine.goal ? ', goal' : ''}',
                child: AnimatedContainer(
                  duration: motion,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: flooded
                          ? const [Color(0xFF82D3D6), Color(0xFF45AEB8)]
                          : height >= 4
                              ? const [Color(0xFFC1E9A9), Color(0xFF84BC82)]
                              : const [Color(0xFFECDDAD), Color(0xFFD0B87D)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: motion,
                    switchInCurve: Curves.easeOutBack,
                    child: player
                        ? const Icon(
                            Icons.directions_run_rounded,
                            key: ValueKey('tide-player'),
                            color: Color(0xFF205C5C), size: 24)
                        : cell == _engine.goal
                            ? const Icon(Icons.flag_rounded,
                                key: ValueKey('tide-goal'),
                                color: Colors.white, size: 21)
                            : flooded
                                ? const Icon(Icons.water_rounded,
                                    key: ValueKey('tide-water'),
                                    color: Color(0xFFC6F4EE), size: 15)
                                : const SizedBox.shrink(
                                    key: ValueKey('tide-empty')),
                  ),
                ),
              );
            },
          ),
        )),
        const SizedBox(height: 9),
        _TidePad(onStep: _step, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 11 ? 3 : 2, detail: 'Reached high ground before the tide.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(8), child: RetryPanel(palette: _palette,
          title: 'THE TIDE CAUGHT YOU', detail: 'Stay on the raised green path.', onRetry: replayLevel))
        else Shake(
          trigger: _blockedPulse,
          child: HintLine(_feedback, palette: _palette),
        ),
      ]));
    }));
}

class _TidePad extends StatelessWidget {
  const _TidePad({required this.onStep, required this.disabled});
  final void Function(int, int) onStep; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, children: [
      const SizedBox(), _move(Icons.keyboard_arrow_up_rounded, 'Move up', -1, 0), const SizedBox(),
      _move(Icons.keyboard_arrow_left_rounded, 'Move left', 0, -1), const SizedBox(),
      _move(Icons.keyboard_arrow_right_rounded, 'Move right', 0, 1),
      const SizedBox(), _move(Icons.keyboard_arrow_down_rounded, 'Move down', 1, 0), const SizedBox(),
    ]));
  Widget _move(IconData icon, String tooltip, int dr, int dc) => ChunkyIconButton(icon: icon, tooltip: tooltip, palette: _palette,
    onPressed: disabled ? null : () => onStep(dr, dc));
}
