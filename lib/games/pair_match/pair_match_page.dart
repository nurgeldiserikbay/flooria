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
  String _feedback = 'TURN TWO CARDS TO FIND A MATCH';
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
    _feedback = 'TURN TWO CARDS TO FIND A MATCH';
  }

  void _tap(int index) {
    if (_locked || reported) return;
    final result = _engine.tap(index);
    if (result == PairTap.ignored) return;
    setState(() {
      _feedback = switch (result) {
        PairTap.flipped => 'ONE CARD REVEALED · FIND ITS MATCH',
        PairTap.mismatch => 'NOT A MATCH · REMEMBER BOTH SYMBOLS',
        PairTap.matched => 'MATCH FOUND · ${_engine.pairCount - _engine.pairsFound} PAIRS LEFT',
        PairTap.completed => 'ALL PAIRS FOUND · GREAT MEMORY!',
        PairTap.ignored => _feedback,
      };
    });
    if (result == PairTap.mismatch) {
      _locked = true;
      HapticFeedback.selectionClick();
      _mismatchTimer = Timer(const Duration(milliseconds: 620), () {
        if (!mounted) return;
        setState(() {
          _engine.hideMismatch();
          _locked = false;
          _feedback = 'CARDS HIDDEN · TRY ANOTHER PAIR';
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
          Semantics(
            key: const ValueKey('pair-board-state'),
            label: '${_engine.pairsFound} of ${_engine.pairCount} pairs matched. '
                '${_engine.attempts} attempts. '
                '${_engine.revealed.length} cards revealed.',
            child: SizedBox(width: width, height: height,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _engine.symbols.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemBuilder: (context, index) => _MemoryCard(
                key: ValueKey('pair-card-$index'),
                index: index,
                symbol: _engine.symbols[index],
                open: _engine.revealed.contains(index) || _engine.matched.contains(index),
                matched: _engine.matched.contains(index),
                onTap: () => _tap(index),
              ),
            ))),
          const SizedBox(height: 12),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.attempts <= _engine.pairCount + 2 ? 3 : 2,
                detail: 'You found every pair.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            HintLine(_feedback, palette: _palette),
        ]));
    }),
  );
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({super.key, required this.index, required this.symbol, required this.open,
    required this.matched, required this.onTap});
  final int index;
  final int symbol;
  final bool open, matched;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: 'Card ${index + 1}, '
          '${matched ? 'matched' : open ? 'revealed' : 'hidden'}'
          '${open ? ', ${['star', 'heart', 'lightning', 'leaf', 'cloud', 'paw', 'sun', 'flower'][symbol]}' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: matched ? null : onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: open ? 1 : 0),
            duration: reduceMotion
                ? Duration.zero : const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            builder: (context, turn, _) {
              final front = turn >= .5;
              final angle = front ? (turn - 1) * pi : turn * pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .001)
                  ..rotateY(angle),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: front
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              _symbolColors[symbol].withValues(alpha: .19),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD6E2),
                              Color(0xFFE8A8C3),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: matched
                          ? const Color(0xFF62B890)
                          : _palette.edge,
                      width: matched ? 2.5 : 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: matched
                            ? const Color(0x4462B890)
                            : const Color(0x334B3340),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        front ? _symbols[symbol] : Icons.auto_awesome_rounded,
                        size: front ? 31 : 26,
                        color: front ? _symbolColors[symbol] : Colors.white,
                      ),
                      if (front && matched)
                        const Positioned(
                          top: 5,
                          right: 5,
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: Color(0xFF59AD85),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
