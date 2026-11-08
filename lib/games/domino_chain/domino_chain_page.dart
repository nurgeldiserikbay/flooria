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
  int _wrongPulse = 0;
  String _feedback = 'PLACE A DOMINO THAT MATCHES THE OPEN NUMBER';
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = DominoChainEngine.forLevel(level);
    _wrongPulse = 0;
    _feedback = 'PLACE A DOMINO THAT MATCHES THE OPEN NUMBER';
  }

  void _place(int id) {
    final result = _engine.place(id);
    if (result == DominoMove.ignored) return;
    if (result == DominoMove.blocked) {
      setState(() {
        _wrongPulse++;
        _feedback = 'NOT A MATCH · FIND A TILE WITH ${_engine.openValue}';
      });
      HapticFeedback.selectionClick();
      return;
    }
    setState(() {
      _feedback = result == DominoMove.completed
          ? 'CHAIN COMPLETE · EVERY TILE CONNECTS!'
          : 'GOOD MATCH · NEXT OPEN NUMBER IS ${_engine.openValue}';
    });
    if (result == DominoMove.completed) {
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
    child: LayoutBuilder(builder: (context, constraints) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration = reduceMotion
          ? Duration.zero : const Duration(milliseconds: 220);
      return Center(
      child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'PLACED', value: '${_engine.placed.length}/${_engine.tiles.length}', palette: _palette),
                StatChip(label: 'MISTAKES', value: '${_engine.mistakes}', palette: _palette),
              ])),
          const SizedBox(height: 14),
          Semantics(
            key: const ValueKey('domino-chain-state'),
            label: '${_engine.placed.length} of ${_engine.tiles.length} dominoes placed. '
                'Open number ${_engine.openValue}. '
                '${_engine.mistakes} incorrect attempts.',
            child: Container(
            width: constraints.maxWidth - 34,
            constraints: const BoxConstraints(minHeight: 92, maxHeight: 170),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE5D7BE)),
              boxShadow: const [
                BoxShadow(color: Color(0x2853483A),
                  blurRadius: 15, offset: Offset(0, 5)),
              ],
            ),
            child: SingleChildScrollView(child: Wrap(alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center, spacing: 5, runSpacing: 6,
              children: [
                _Pip(value: _engine.startValue, size: 34),
                for (final tile in _engine.placed)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('domino-placed-${tile.id}'),
                    tween: Tween(begin: .86, end: 1),
                    duration: duration,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _DominoFace(tile: tile, compact: true),
                  ),
              ])),
          )),
          const SizedBox(height: 12),
          Shake(
            trigger: _wrongPulse,
            child: Container(
              key: const ValueKey('domino-open-end'),
              padding: const EdgeInsets.symmetric(
                horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAC8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6D0A8)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('OPEN END', style: TextStyle(
                  color: Color(0xFF93836D), fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(width: 9),
                AnimatedSwitcher(
                  duration: duration,
                  child: Text('${_engine.openValue}',
                    key: ValueKey('domino-value-${_engine.openValue}'),
                    style: const TextStyle(
                      color: Color(0xFF83551F),
                      fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
            children: [for (final tile in _engine.tiles)
              if (!_engine.used.contains(tile.id))
                Semantics(
                  button: true,
                  enabled: !reported,
                  label: 'Domino ${tile.left} to ${tile.right}, '
                      '${tile.left == _engine.openValue || tile.right == _engine.openValue ? 'matches open number' : 'does not match open number'}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('domino-choice-${tile.id}'),
                      onTap: reported ? null : () => _place(tile.id),
                      borderRadius: BorderRadius.circular(10),
                      child: _DominoFace(
                        tile: tile,
                        hint: tile.left == _engine.openValue ||
                            tile.right == _engine.openValue,
                      ),
                    ),
                  ),
                ),
            ]),
          const SizedBox(height: 16),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.mistakes == 0 ? 3 : _engine.mistakes < 3 ? 2 : 1,
                detail: 'Every domino connects to the open end.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            HintLine(_feedback, palette: _palette),
        ],
      )),
    );
    }),
  );
}

class _DominoFace extends StatelessWidget {
  const _DominoFace({
    required this.tile,
    this.compact = false,
    this.hint = false,
  });
  final DominoTile tile;
  final bool compact;
  final bool hint;
  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 48.0;
    final width = compact ? 58.0 : 76.0;
    return AnimatedContainer(
      duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero : const Duration(milliseconds: 175),
      width: width, height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hint
              ? const [Color(0xFFFFFCF3), Color(0xFFFFE9BD)]
              : const [Colors.white, Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hint ? _palette.accent : const Color(0xFFCFC0A7),
          width: hint ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: hint ? const Color(0x44D39B4E)
              : const Color(0x22483B2D),
            blurRadius: hint ? 9 : 5,
            offset: const Offset(0, 3)),
        ],
      ),
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
