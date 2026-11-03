import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'lights_out_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF2F9), surface: Colors.white, ink: Color(0xFF344A5F),
  muted: Color(0xFF7B90A2), accent: Color(0xFF4E9DA5), edge: Color(0xFF344A5F),
);

Widget buildLightsOutPage(BuildContext context, GameLaunch launch) =>
    LightsOutPage(launch: launch);

class LightsOutPage extends StatefulWidget {
  const LightsOutPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<LightsOutPage> createState() => _LightsOutPageState();
}

class _LightsOutPageState extends State<LightsOutPage> with LevelFlow<LightsOutPage> {
  late LightsOutEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = LightsOutEngine.forLevel(level);

  void _press(int cell) {
    final result = _engine.press(cell);
    if (result == LightMove.ignored) return;
    setState(() {});
    if (result == LightMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Lights Out',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth - 30,
        constraints.maxHeight - (reported ? 245 : 185)).clamp(250.0, 410.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'LIGHTS ON', value: '${_engine.litCount}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 16),
          Container(width: side, height: side, padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFC9D8E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 5))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.lights.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: LightsOutEngine.side,
                crossAxisSpacing: 7, mainAxisSpacing: 7),
              itemBuilder: (context, cell) {
                final lit = _engine.lights[cell];
                return Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _press(cell),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: lit ? const Color(0xFFFFD875) : const Color(0xFFEAF0F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lit ? const Color(0xFFE4AE43)
                          : const Color(0xFFCAD6DD), width: 1.5),
                        boxShadow: lit ? const [BoxShadow(color: Color(0x66F5C766),
                          blurRadius: 8, spreadRadius: 1)] : null,
                      ),
                      child: Icon(lit ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                        size: side / 14, color: lit ? const Color(0xFFB47B22)
                          : const Color(0xFF9BAAB4)),
                    )),
                );
              },
            )),
          const SizedBox(height: 16),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 8 + level ? 3 : 2,
                detail: 'Every light is switched off.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('EACH TAP TOGGLES NEIGHBOURING LIGHTS', palette: _palette),
        ]));
    }),
  );
}
