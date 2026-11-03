import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'shadow_bridge_engine.dart';

const _palette = GamePalette(ground: Color(0xFFEAF5F4), surface: Colors.white, ink: Color(0xFF3F5E60),
  muted: Color(0xFF7E9A9C), accent: Color(0xFF53A7A2), edge: Color(0xFF3F5E60));
Widget buildShadowBridgePage(BuildContext context, GameLaunch launch) => ShadowBridgePage(launch: launch);

class ShadowBridgePage extends StatefulWidget {
  const ShadowBridgePage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<ShadowBridgePage> createState() => _ShadowBridgePageState();
}

class _ShadowBridgePageState extends State<ShadowBridgePage> with LevelFlow<ShadowBridgePage> {
  late ShadowBridgeEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = ShadowBridgeEngine.forLevel(level);
  void _step(int dr, int dc) {
    final result = _engine.step(dr, dc); setState(() {});
    if (result == ShadowMove.completed) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }
  void _lamp() { _engine.turnLamp(); setState(() {}); HapticFeedback.selectionClick(); }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Shadow Bridge', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 360 : 305)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFE6AF4A)), const SizedBox(width: 8),
          Text(_engine.lightPhase == 0 ? 'SUNLIGHT' : 'MOONLIGHT', style: TextStyle(color: _palette.ink, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(width: 10), SizedBox(width: 42, height: 40, child: ChunkyButton(onPressed: reported || _engine.isFailed ? null : _lamp,
            color: _palette.accent, edgeColor: _palette.edge, padding: EdgeInsets.zero, child: const Icon(Icons.wb_twilight_rounded, color: Colors.white))),
        ]),
        const SizedBox(height: 8),
        Container(width: side, height: side, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFD7E8E7),
          borderRadius: BorderRadius.circular(19), border: Border.all(color: _palette.edge, width: 2)),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final isVoid = ShadowBridgeEngine.voidCells.contains(cell);
              final safeShadow = _engine.bridgeCells.contains(cell) && ((cell.isEven && _engine.lightPhase == 0) || (cell.isOdd && _engine.lightPhase == 1));
              final color = cell == _engine.position ? const Color(0xFF58A9A1) : isVoid ? (safeShadow ? const Color(0xFF8EC8B2) : const Color(0xFF477174)) : Colors.white;
              return AnimatedContainer(duration: const Duration(milliseconds: 180), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                child: Center(child: cell == _engine.position ? const Icon(Icons.person_pin_circle_rounded, color: Colors.white)
                  : cell == ShadowBridgeEngine.goal ? const Icon(Icons.flag_rounded, color: Color(0xFFF0B449))
                  : isVoid && !safeShadow ? const Icon(Icons.water_drop_rounded, color: Color(0xFF9CC7C7), size: 17) : null));
            })),
        const SizedBox(height: 8),
        _ShadowPad(onStep: _step, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 9 ? 3 : 2, detail: 'Crossed the bridge in the safe light.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(8), child: RetryPanel(palette: _palette,
          title: 'LOST IN THE DARK', detail: 'Turn the lamp to reveal the next shadow tile.', onRetry: replayLevel))
        else const HintLine('SWITCH LIGHT TO REVEAL EACH SHADOW', palette: _palette),
      ]));
    }));
}

class _ShadowPad extends StatelessWidget {
  const _ShadowPad({required this.onStep, required this.disabled});
  final void Function(int, int) onStep; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, children: [
      const SizedBox(), _move(Icons.keyboard_arrow_up_rounded, -1, 0), const SizedBox(),
      _move(Icons.keyboard_arrow_left_rounded, 0, -1), const SizedBox(), _move(Icons.keyboard_arrow_right_rounded, 0, 1),
      const SizedBox(), _move(Icons.keyboard_arrow_down_rounded, 1, 0), const SizedBox(),
    ]));
  Widget _move(IconData icon, int dr, int dc) => ChunkyIconButton(icon: icon, tooltip: 'Move', palette: _palette,
    onPressed: disabled ? null : () => onStep(dr, dc));
}
