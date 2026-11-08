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
  String _feedback = 'SWITCH LIGHT TO REVEAL EACH SHADOW';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = ShadowBridgeEngine.forLevel(level);
    _feedback = 'SWITCH LIGHT TO REVEAL EACH SHADOW';
  }
  void _step(int dr, int dc) {
    final result = _engine.step(dr, dc);
    if (result == ShadowMove.ignored) return;
    setState(() {
      _feedback = result == ShadowMove.blocked
          ? 'PATH BLOCKED · TRY ANOTHER DIRECTION OR CHANGE THE LIGHT'
          : 'GOOD STEP · FIND THE SAFE SHADOW BRIDGE';
    });
    if (result == ShadowMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == ShadowMove.blocked) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }
  void _lamp() {
    final result = _engine.turnLamp();
    if (result == ShadowMove.ignored) return;
    setState(() {
      _feedback = result == ShadowMove.blocked
          ? 'LIGHT CHANGED · FIND SOLID GROUND TO CROSS'
          : 'LIGHT CHANGED · FOLLOW THE BRIGHT BRIDGE';
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GameScaffold(palette: _palette, title: 'Shadow Bridge', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported || _engine.isFailed ? 360 : 305)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_engine.lightPhase == 0 ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: const Color(0xFFE6AF4A)), const SizedBox(width: 8),
          Text(_engine.lightPhase == 0 ? 'SUNLIGHT' : 'MOONLIGHT', style: TextStyle(color: _palette.ink, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(width: 10), SizedBox(width: 42, height: 40, child: ChunkyButton(onPressed: reported || _engine.isFailed ? null : _lamp,
            semanticLabel: 'Switch between sunlight and moonlight',
            color: _palette.accent, edgeColor: _palette.edge, padding: EdgeInsets.zero, child: const Icon(Icons.wb_twilight_rounded, color: Colors.white))),
        ]),
        const SizedBox(height: 8),
        Semantics(
          key: const ValueKey('shadow-board-state'),
          label: '${_engine.lightPhase == 0 ? 'Sunlight' : 'Moonlight'}, '
              'player at row ${_engine.position ~/ ShadowBridgeEngine.side + 1}, '
              'column ${_engine.position % ShadowBridgeEngine.side + 1}. '
              'Green bridges are safe to cross.',
          child: Container(width: side, height: side, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFD7E8E7),
          borderRadius: BorderRadius.circular(19), border: Border.all(color: _palette.edge, width: 2)),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final isVoid = ShadowBridgeEngine.voidCells.contains(cell);
              final safeShadow = _engine.bridgeCells.contains(cell) && ((cell.isEven && _engine.lightPhase == 0) || (cell.isOdd && _engine.lightPhase == 1));
              final color = cell == _engine.position ? const Color(0xFF58A9A1) : isVoid ? (safeShadow ? const Color(0xFF8EC8B2) : const Color(0xFF477174)) : Colors.white;
              return AnimatedContainer(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                child: Center(child: cell == _engine.position ? const Icon(Icons.person_pin_circle_rounded, color: Colors.white)
                  : cell == ShadowBridgeEngine.goal ? const Icon(Icons.flag_rounded, color: Color(0xFFF0B449))
                  : isVoid && !safeShadow ? const Icon(Icons.water_drop_rounded, color: Color(0xFF9CC7C7), size: 17) : null));
            }))),
        const SizedBox(height: 8),
        _ShadowPad(onStep: _step, disabled: reported || _engine.isFailed),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.moves <= 9 ? 3 : 2, detail: 'Crossed the bridge in the safe light.', onReplay: replayLevel, onNext: nextLevel))
        else if (_engine.isFailed) Padding(padding: const EdgeInsets.all(8), child: RetryPanel(palette: _palette,
          title: 'LOST IN THE DARK', detail: 'Turn the lamp to reveal the next shadow tile.', onRetry: replayLevel))
        else HintLine(_feedback, palette: _palette),
      ]));
    }));
  }
}

class _ShadowPad extends StatelessWidget {
  const _ShadowPad({required this.onStep, required this.disabled});
  final void Function(int, int) onStep; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, children: [
      const SizedBox(), _move(Icons.keyboard_arrow_up_rounded, 'Move up', -1, 0), const SizedBox(),
      _move(Icons.keyboard_arrow_left_rounded, 'Move left', 0, -1), const SizedBox(), _move(Icons.keyboard_arrow_right_rounded, 'Move right', 0, 1),
      const SizedBox(), _move(Icons.keyboard_arrow_down_rounded, 'Move down', 1, 0), const SizedBox(),
    ]));
  Widget _move(IconData icon, String label, int dr, int dc) => ChunkyIconButton(icon: icon, tooltip: label, palette: _palette,
    onPressed: disabled ? null : () => onStep(dr, dc));
}
