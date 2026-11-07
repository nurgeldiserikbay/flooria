import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'combination_lock_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFF5F0E6), surface: Colors.white, ink: Color(0xFF584D3D),
  muted: Color(0xFF92836E), accent: Color(0xFFC99A52), edge: Color(0xFF584D3D),
);

Widget buildCombinationLockPage(BuildContext context, GameLaunch launch) =>
    CombinationLockPage(launch: launch);

class CombinationLockPage extends StatefulWidget {
  const CombinationLockPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<CombinationLockPage> createState() => _CombinationLockPageState();
}

class _CombinationLockPageState extends State<CombinationLockPage>
    with LevelFlow<CombinationLockPage> {
  late CombinationLockEngine _engine;
  int _wrongPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = CombinationLockEngine.forLevel(level);
    _wrongPulse = 0;
  }

  void _digit(int digit) {
    final result = _engine.enterDigit(digit);
    if (result == LockMove.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  void _submit() {
    final result = _engine.submit();
    if (result == LockMove.ignored) return;
    setState(() {
      if (result == LockMove.submitted || result == LockMove.failed) {
        _wrongPulse++;
      }
    });
    if (result == LockMove.solved) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else if (result == LockMove.failed) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Combination Lock', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final width = min(constraints.maxWidth - 36, 380.0).toDouble();
      final slotWidth = min(54.0,
          (width - 50 - (_engine.codeLength - 1) * 6) /
              _engine.codeLength).toDouble();
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final clues = _engine.clues.reversed.take(4).toList();
      return Center(child: SingleChildScrollView(
        child: SizedBox(width: width,
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: width - 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatChip(
                        label: 'TRIES LEFT',
                        value: '${_engine.attemptsLeft}',
                        palette: _palette,
                      ),
                      const SizedBox(width: 12),
                      StatChip(
                        label: 'CODE',
                        value: '${_engine.codeLength} DIGITS',
                        palette: _palette,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Shake(
              trigger: _wrongPulse,
              child: SizedBox(
                width: width,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  for (var slot = 0; slot < _engine.codeLength; slot++) ...[
                    if (slot > 0) const SizedBox(width: 6),
                    Semantics(
                      key: ValueKey('lock-slot-$slot'),
                      button: true,
                      selected: _engine.activeSlot == slot,
                      label: 'Digit ${slot + 1} of ${_engine.codeLength}, '
                          '${_engine.input[slot]?.toString() ?? 'empty'}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: reported || _engine.isFailed
                              ? null : () => setState(
                                  () => _engine.selectSlot(slot)),
                          borderRadius: BorderRadius.circular(13),
                          child: AnimatedScale(
                            scale: _engine.activeSlot == slot ? 1 : .97,
                            duration: reduceMotion ? Duration.zero
                                : const Duration(milliseconds: 140),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: reduceMotion ? Duration.zero
                                  : const Duration(milliseconds: 170),
                              width: slotWidth,
                              height: 63,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _engine.activeSlot == slot
                                      ? const [
                                          Color(0xFFFFEAC7),
                                          Color(0xFFFFD994),
                                        ]
                                      : const [
                                          Colors.white,
                                          Color(0xFFFFF9EC),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _engine.activeSlot == slot
                                      ? _palette.accent
                                      : const Color(0xFFDCCFBA),
                                  width: _engine.activeSlot == slot ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _engine.activeSlot == slot
                                        ? const Color(0x44C99A52)
                                        : const Color(0x22584D3D),
                                    blurRadius: _engine.activeSlot == slot
                                        ? 9 : 4,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: reduceMotion ? Duration.zero
                                    : const Duration(milliseconds: 140),
                                child: Text(
                                  _engine.input[slot]?.toString() ?? '·',
                                  key: ValueKey(
                                      'lock-slot-value-$slot-${_engine.input[slot]}'),
                                  style: TextStyle(
                                    color: _palette.ink,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ChunkyIconButton(
                    icon: Icons.backspace_outlined,
                    tooltip: 'Clear digit',
                    palette: _palette,
                    onPressed: reported || _engine.isFailed ? null
                        : () => setState(() { _engine.clearActive(); }),
                    size: 42,
                  ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 7,
              children: [for (var digit = 0; digit <= 9; digit++)
                SizedBox(width: (width - 4 * 8) / 5, height: 45,
                  child: ChunkyButton(
                    key: ValueKey('lock-key-$digit'),
                    onPressed: reported || _engine.isFailed
                    ? null : () => _digit(digit),
                    color: Colors.white, edgeColor: _palette.edge, depth: 3,
                    radius: 10, padding: EdgeInsets.zero,
                    child: Text('$digit', style: TextStyle(color: _palette.ink,
                      fontSize: 18, fontWeight: FontWeight.w900)))),
              ]),
            const SizedBox(height: 9),
            SizedBox(width: 210, height: 47,
              child: ChunkyButton(onPressed: reported || _engine.isFailed ? null : _submit,
                color: _palette.accent, edgeColor: _palette.edge, depth: 4, radius: 13,
                child: const Text('TRY CODE', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, letterSpacing: 1)))),
            const SizedBox(height: 8),
            for (final clue in clues)
              Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final digit in clue.guess)
                    Container(width: 27, height: 28, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE7D6B8))),
                      child: Center(child: Text('$digit', style: TextStyle(color: _palette.ink,
                        fontWeight: FontWeight.w900)))),
                  const SizedBox(width: 7),
                  Text('${clue.exact} EXACT · ${clue.misplaced} ELSEWHERE',
                    style: TextStyle(color: _palette.muted, fontSize: 9,
                      fontWeight: FontWeight.w900, letterSpacing: .4)),
                ])),
            if (reported) ...[
              const SizedBox(height: 8),
              LevelResultPanel(palette: _palette, launch: launch,
                level: level, stars: _engine.clues.length <= 4 ? 3
                  : _engine.clues.length <= 7 ? 2 : 1,
                detail: 'Cracked the code from the clues.',
                onReplay: replayLevel, onNext: nextLevel),
            ] else if (_engine.isFailed) ...[
              const SizedBox(height: 8),
              RetryPanel(palette: _palette, title: 'LOCK STILL CLOSED',
                detail: 'Use the clues to deduce the code.', onRetry: replayLevel),
            ] else
              const HintLine('EXACT = RIGHT DIGIT AND POSITION', palette: _palette),
          ],
        ),
      ),
      ));
    }),
  );
}
