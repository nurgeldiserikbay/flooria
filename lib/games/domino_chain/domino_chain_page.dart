import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'domino_chain_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF6F0E6), surface: Colors.white, ink: Color(0xFF53483A),
  muted: Color(0xFF93836D), accent: Color(0xFFD39B4E), edge: Color(0xFF53483A),
);

Widget buildDominoChainPage(BuildContext context, GameLaunch launch) =>
    DominoChainPage(launch: launch);

class DominoChainPage extends StatefulWidget {
  const DominoChainPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<DominoChainPage> createState() => _DominoChainPageState();
}

class _DominoChainPageState extends State<DominoChainPage> with LevelFlow<DominoChainPage> {
  late DominoChainEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = DominoChainEngine.forLevel(level);

  void _place(int id) {
    final result = _engine.place(id);
    if (result == DominoMove.ignored) return;
    setState(() {});
    if (result == DominoMove.blocked) {
      HapticFeedback.selectionClick();
    } else if (result == DominoMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Domino Chain',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) => Center(
      child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'PLACED', value: '${_engine.placed.length}/${_engine.tiles.length}', palette: _palette),
                StatChip(label: 'MISTAKES', value: '${_engine.mistakes}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Container(width: constraints.maxWidth - 34,
            constraints: const BoxConstraints(minHeight: 92, maxHeight: 170),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _palette.edge, width: 2),
              boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 4))]),
            child: SingleChildScrollView(child: Wrap(alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center, spacing: 5, runSpacing: 6,
              children: [
                _Pip(value: _engine.startValue, size: 34),
                for (final tile in _engine.placed) _DominoFace(tile: tile, compact: true),
              ])),
          ),
          const SizedBox(height: 12),
          Text('OPEN END  ${_engine.openValue}', style: const TextStyle(
            color: _palette.muted, fontSize: 11, fontWeight: FontWeight.w900,
            letterSpacing: 1)),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
            children: [for (final tile in _engine.tiles)
              if (!_engine.used.contains(tile.id))
                Material(color: Colors.transparent,
                  child: InkWell(onTap: reported ? null : () => _place(tile.id),
                    borderRadius: BorderRadius.circular(10),
                    child: _DominoFace(tile: tile))),
            ]),
          const SizedBox(height: 16),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.mistakes == 0 ? 3 : _engine.mistakes < 3 ? 2 : 1,
                detail: 'Every domino connects to the open end.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('PLACE A DOMINO THAT MATCHES THE OPEN NUMBER', palette: _palette),
        ],
      )),
    )),
  );
}

class _DominoFace extends StatelessWidget {
  const _DominoFace({required this.tile, this.compact = false});
  final DominoTile tile;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 48.0;
    final width = compact ? 58.0 : 76.0;
    return Container(width: width, height: height,
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _palette.edge, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33483B2D), offset: Offset(0, 3))]),
      child: Row(children: [
        Expanded(child: _Pip(value: tile.left, size: compact ? 20 : 28)),
        Container(width: 1.5, color: const Color(0xFFB6A991)),
        Expanded(child: _Pip(value: tile.right, size: compact ? 20 : 28)),
      ]),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.value, required this.size});
  final int value;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: Center(child: Text('$value', style: TextStyle(color: _palette.ink,
      fontSize: size * .52, fontWeight: FontWeight.w900))));
}
