import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'water_sort_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF4F4), surface: Colors.white, ink: Color(0xFF385354),
  muted: Color(0xFF789393), accent: Color(0xFF48A5A0), edge: Color(0xFF385354),
);
const _colors = [
  Color(0xFFE87468), Color(0xFFE7B94F), Color(0xFF65B982),
  Color(0xFF579BD1), Color(0xFF9A76C9),
];

Widget buildWaterSortPage(BuildContext context, GameLaunch launch) =>
    WaterSortPage(launch: launch);

class WaterSortPage extends StatefulWidget {
  const WaterSortPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<WaterSortPage> createState() => _WaterSortPageState();
}

class _WaterSortPageState extends State<WaterSortPage> with LevelFlow<WaterSortPage> {
  late WaterSortEngine _engine;
  int _blockedPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = WaterSortEngine.forLevel(level);
    _blockedPulse = 0;
  }

  void _tap(int tube) {
    final result = _engine.tapTube(tube);
    if (result == PourAction.ignored) {
      setState(() {});
      return;
    }
    if (result == PourAction.blocked) {
      HapticFeedback.selectionClick();
      setState(() => _blockedPulse++);
      return;
    }
    setState(() {});
    if (result == PourAction.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Water Sort',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final tubeHeight = min(150.0, constraints.maxHeight - (reported ? 250 : 190))
        .clamp(112.0, 150.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'COLORS', value: '${_engine.colors}', palette: _palette),
                StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
              ])),
          const SizedBox(height: 26),
          Shake(
            trigger: _blockedPulse,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 28,
              children: [
                for (var index = 0; index < _engine.tubes.length; index++)
                  _Tube(
                    key: ValueKey('water-tube-$index'),
                    tube: _engine.tubes[index],
                    selected: _engine.selectedTube == index,
                    height: tubeHeight,
                    onTap: reported ? null : () => _tap(index),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= _engine.colors * 3 ? 3 : 2,
                detail: 'Every colour is sorted into its own tube.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('TAP A TUBE, THEN POUR INTO A MATCHING TUBE', palette: _palette),
        ]));
    }),
  );
}

class _Tube extends StatelessWidget {
  const _Tube({super.key, required this.tube, required this.selected,
    required this.height, required this.onTap});
  final List<int> tube;
  final bool selected;
  final double height;
  final VoidCallback? onTap;
  Widget _liquidLayer(int slot, bool reduceMotion) {
    final filled = slot < tube.length;
    final liquid = filled ? _colors[tube[slot]] : Colors.transparent;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: filled ? null : Colors.transparent,
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(liquid, Colors.white, .28)!,
                      liquid,
                      GamePalette.shade(liquid, .12),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(5),
            border: filled
                ? Border.all(color: Colors.white.withValues(alpha: .35))
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: selected ? 'Selected water tube' : 'Water tube',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: reduceMotion
              ? Duration.zero : const Duration(milliseconds: 170),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero : const Duration(milliseconds: 170),
            transform: Matrix4.translationValues(0, selected ? -9 : 0, 0),
            width: 48,
            height: height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFD9F4F7)],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(17),
                top: Radius.circular(9),
              ),
              border: Border.all(
                color: selected
                    ? _palette.accent : const Color(0xFF8BAEB7),
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? const Color(0x5548A5A0) : const Color(0x22506060),
                  blurRadius: selected ? 12 : 3,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var slot = WaterSortEngine.capacity - 1; slot >= 0; slot--)
                  _liquidLayer(slot, reduceMotion),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
