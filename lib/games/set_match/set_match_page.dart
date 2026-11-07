import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'set_match_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF5F1FF), surface: Colors.white, ink: Color(0xFF514B6D),
  muted: Color(0xFF8982A5), accent: Color(0xFF8A72C4), edge: Color(0xFF514B6D),
);
const _setColors = [Color(0xFFDC6F81), Color(0xFF58A789), Color(0xFF638FD0)];

Widget buildSetMatchPage(BuildContext context, GameLaunch launch) =>
    SetMatchPage(launch: launch);

class SetMatchPage extends StatefulWidget {
  const SetMatchPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<SetMatchPage> createState() => _SetMatchPageState();
}

class _SetMatchPageState extends State<SetMatchPage> with LevelFlow<SetMatchPage> {
  late SetMatchEngine _engine;
  String _message = 'FIND 2 SETS';
  int _invalidPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = SetMatchEngine.forLevel(level);
    _message = 'FIND 2 SETS';
    _invalidPulse = 0;
  }

  void _tap(int card) {
    final result = _engine.tap(card);
    if (result == SetMove.ignored) return;
    setState(() {
      _message = switch (result) {
        SetMove.invalid => 'NOT A SET · EACH FEATURE MUST MATCH OR DIFFER',
        SetMove.found => 'NICE SET · FIND ONE MORE',
        SetMove.completed => 'BOTH SETS FOUND',
        SetMove.selected => 'SELECT 3 CARDS',
        SetMove.ignored => _message,
      };
      if (result == SetMove.invalid) _invalidPulse++;
    });
    if (result == SetMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == SetMove.invalid) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Find a Set', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final width = min(constraints.maxWidth - 28, 390.0).toDouble();
      final cardHeight = min(78.0, (constraints.maxHeight - 250) / 3).clamp(55.0, 78.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              StatChip(label: 'SETS', value: '${_engine.setsFound}/${_engine.goalSets}', palette: _palette),
              StatChip(label: 'CARDS', value: '${_engine.cards.where((card) => card != null).length}', palette: _palette),
            ])),
          const SizedBox(height: 12),
          SizedBox(width: width, height: cardHeight * 3 + 12,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
              itemCount: _engine.cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6,
                childAspectRatio: ((width - 18) / 4) / cardHeight),
              itemBuilder: (context, index) {
                final card = _engine.cards[index];
                final selected = _engine.selected.contains(index);
                final duration =
                    MediaQuery.maybeOf(context)?.disableAnimations == true
                        ? Duration.zero
                        : const Duration(milliseconds: 180);
                return Semantics(
                  key: ValueKey('set-card-$index'),
                  button: card != null,
                  enabled: !reported && card != null,
                  label: card == null
                      ? 'Matched card ${index + 1}'
                      : 'Card ${index + 1}, ${card.count} shapes, '
                          '${selected ? 'selected' : 'not selected'}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: reported || card == null
                          ? null : () => _tap(index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedScale(
                        scale: selected ? .95 : 1,
                        duration: duration,
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: card == null
                                ? const Color(0xFFEAF4EF)
                                : selected
                                    ? const Color(0xFFEDE6F9)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? _palette.accent
                                  : const Color(0xFFDDD7E9),
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected
                                    ? const Color(0x338A72C4)
                                    : const Color(0x174E466A),
                                blurRadius: selected ? 12 : 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: duration,
                            switchInCurve: Curves.easeOutBack,
                            child: card == null
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('set-matched'),
                                    color: Color(0xFF54AB83),
                                  )
                                : Row(
                                    key: const ValueKey('set-symbols'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (var i = 0; i < card.count; i++)
                                        _SetSymbol(
                                          card: card,
                                          color: _setColors[card.color],
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )),
          const SizedBox(height: 12),
          if (reported)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.moves <= 4 ? 3 : _engine.moves <= 7 ? 2 : 1,
                detail: 'Found two triples with matching or different features.',
                onReplay: replayLevel, onNext: nextLevel))
          else
            Shake(
              trigger: _invalidPulse,
              child: HintLine(_message, palette: _palette),
            ),
        ]));
    }),
  );
}

class _SetSymbol extends StatelessWidget {
  const _SetSymbol({required this.card, required this.color});
  final MatchCard card;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(17, 24), painter: _SymbolPainter(card.shape, card.fill, color));
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter(this.shape, this.fill, this.color);
  final int shape;
  final int fill;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 3, size.width - 4, size.height - 6);
    final path = Path();
    if (shape == 0) {
      path.addOval(rect);
    } else if (shape == 1) {
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)));
    } else {
      path.moveTo(rect.center.dx, rect.top);
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      path.close();
    }
    if (fill == 0) {
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      canvas.drawPath(path, Paint()..color = fill == 1 ? color : color.withValues(alpha: .25));
      if (fill == 2) {
        canvas.save();
        canvas.clipPath(path);
        final stripes = Paint()..color = color..strokeWidth = 1;
        for (var x = -size.height; x < size.width + size.height; x += 4) {
          canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripes);
        }
        canvas.restore();
      }
    }
  }
  @override
  bool shouldRepaint(covariant _SymbolPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.fill != fill || oldDelegate.color != color;
}
