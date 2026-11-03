import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'pair_match_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFFFF0E9), surface: Colors.white, ink: Color(0xFF593B49),
  muted: Color(0xFFA17E8C), accent: Color(0xFFE2789A), edge: Color(0xFF593B49),
);
const _symbols = [
  Icons.star_rounded, Icons.favorite_rounded, Icons.bolt_rounded,
  Icons.spa_rounded, Icons.cloud_rounded, Icons.pets_rounded,
  Icons.wb_sunny_rounded, Icons.local_florist_rounded,
];
const _symbolColors = [
  Color(0xFFFFB84D), Color(0xFFE76F87), Color(0xFF7C75D8),
  Color(0xFF53AE8C), Color(0xFF57A4CE), Color(0xFFDF8B53),
  Color(0xFFE9A844), Color(0xFF6CA96A),
];

Widget buildPairMatchPage(BuildContext context, GameLaunch launch) =>
    PairMatchPage(launch: launch);

class PairMatchPage extends StatefulWidget {
  const PairMatchPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<PairMatchPage> createState() => _PairMatchPageState();
}

class _PairMatchPageState extends State<PairMatchPage> with LevelFlow<PairMatchPage> {
  late PairMatchEngine _engine;
  Timer? _mismatchTimer;
  bool _locked = false;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void dispose() { _mismatchTimer?.cancel(); super.dispose(); }
  @override
  void resetLevel() {
    _mismatchTimer?.cancel();
    _locked = false;
    _engine = PairMatchEngine.forLevel(level);
  }

  void _tap(int index) {
    if (_locked || reported) return;
    final result = _engine.tap(index);
    if (result == PairTap.ignored) return;
    setState(() {});
    if (result == PairTap.mismatch) {
      _locked = true;
      HapticFeedback.selectionClick();
      _mismatchTimer = Timer(const Duration(milliseconds: 620), () {
        if (!mounted) return;
        setState(() {
          _engine.hideMismatch();
          _locked = false;
        });
      });
    } else if (result == PairTap.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score,
        metrics: {'memory': max(0, 100 - (_engine.attempts - _engine.pairCount) * 6)});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Pair Match',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final rows = (_engine.symbols.length / 4).ceil();
      final reserve = reported ? 235.0 : 145.0;
      const gap = 8.0;
      final availableWidth = constraints.maxWidth - 28;
      final availableHeight = constraints.maxHeight - reserve;
      final cell = min((availableWidth - gap * 3) / 4,
          (availableHeight - gap * (rows - 1)) / rows)
          .clamp(42.0, 104.0).toDouble();
      final width = cell * 4 + gap * 3;
      final height = cell * rows + gap * (rows - 1);
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatChip(label: 'PAIRS', value: '${_engine.pairsFound}/${_engine.pairCount}', palette: _palette),
                StatChip(label: 'TRIES', value: '${_engine.attempts}', palette: _palette),
              ])),
          const SizedBox(height: 12),
          SizedBox(width: width, height: height,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.symbols.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (context, index) => _MemoryCard(
                key: ValueKey('pair-card-$index-${_engine.revealed.contains(index)}-${_engine.matched.contains(index)}'),
                symbol: _engine.symbols[index],
                open: _engine.revealed.contains(index) || _engine.matched.contains(index),
                matched: _engine.matched.contains(index),
                onTap: () => _tap(index),
              ),
            )),
          const SizedBox(height: 12),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.attempts <= _engine.pairCount + 2 ? 3 : 2,
                detail: 'You found every pair.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            const HintLine('TURN TWO CARDS TO FIND A MATCH', palette: _palette),
        ]));
    }),
  );
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({super.key, required this.symbol, required this.open,
    required this.matched, required this.onTap});
  final int symbol;
  final bool open, matched;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: open
              ? LinearGradient(colors: [Colors.white, _symbolColors[symbol].withValues(alpha: .18)])
              : const LinearGradient(colors: [Color(0xFFF0C4D2), Color(0xFFE7AFC1)]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: matched ? const Color(0xFF66B88E) : _palette.edge,
            width: matched ? 2.5 : 1.5),
          boxShadow: const [BoxShadow(color: Color(0x224B3340),
            offset: Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: open
              ? Icon(_symbols[symbol], key: ValueKey(symbol),
                  size: 30, color: _symbolColors[symbol])
              : const Icon(Icons.auto_awesome_rounded, key: ValueKey('hidden'),
                  size: 25, color: Colors.white),
        ),
      ),
    ),
  );
}
