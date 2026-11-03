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
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = WaterSortEngine.forLevel(level);

  void _tap(int tube) {
    final result = _engine.tapTube(tube);
    if (result == PourAction.ignored) {
      setState(() {});
      return;
    }
    if (result == PourAction.blocked) {
      HapticFeedback.selectionClick();
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
          Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 28,
            children: [for (var index = 0; index < _engine.tubes.length; index++)
              _Tube(tube: _engine.tubes[index], selected: _engine.selectedTube == index,
                height: tubeHeight, onTap: reported ? null : () => _tap(index))]),
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
  const _Tube({required this.tube, required this.selected, required this.height,
    required this.onTap});
  final List<int> tube;
  final bool selected;
  final double height;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
      width: 44,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFF9FFFF),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15),
          top: Radius.circular(8)),
        border: Border.all(color: selected ? _palette.accent : const Color(0xFF91B8B9),
          width: selected ? 3 : 2),
        boxShadow: [BoxShadow(color: selected ? const Color(0x5548A5A0)
          : const Color(0x22506060), offset: const Offset(0, 4))]),
      child: Column(children: [
        for (var slot = WaterSortEngine.capacity - 1; slot >= 0; slot--)
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 1),
            child: Container(
              decoration: BoxDecoration(
                color: slot < tube.length ? _colors[tube[slot]] : Colors.transparent,
                borderRadius: BorderRadius.circular(5)),
            ))),
      ]),
    ),
  );
}
