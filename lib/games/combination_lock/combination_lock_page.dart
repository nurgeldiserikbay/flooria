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
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = CombinationLockEngine.forLevel(level);

  void _digit(int digit) {
    final result = _engine.enterDigit(digit);
    if (result == LockMove.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  void _submit() {
    final result = _engine.submit();
    if (result == LockMove.ignored) return;
    setState(() {});
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
      final clues = _engine.clues.reversed.take(4).toList();
      return Center(child: SizedBox(width: width,
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                StatChip(label: 'TRIES LEFT', value: '${_engine.attemptsLeft}', palette: _palette),
                StatChip(label: 'CODE', value: '${_engine.codeLength} DIGITS', palette: _palette),
              ])),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var slot = 0; slot < _engine.codeLength; slot++) ...[
                if (slot > 0) const SizedBox(width: 8),
                InkWell(onTap: () => setState(() => _engine.selectSlot(slot)),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                    width: min(54, (width - 20) / _engine.codeLength).toDouble(),
                    height: 66,
                    decoration: BoxDecoration(color: _engine.activeSlot == slot
                      ? const Color(0xFFFFE0A5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _engine.activeSlot == slot
                        ? _palette.accent : _palette.edge, width: 2),
                      boxShadow: [BoxShadow(color: _palette.edge, offset: const Offset(0, 4))]),
                    child: Center(child: Text(_engine.input[slot]?.toString() ?? '·',
                      style: TextStyle(color: _palette.ink, fontSize: 28,
                        fontWeight: FontWeight.w900))),
                  )),
              ],
              const SizedBox(width: 10),
              ChunkyIconButton(icon: Icons.backspace_outlined, tooltip: 'Clear digit',
                palette: _palette, onPressed: reported || _engine.isFailed
                  ? null : () => setState(() { _engine.clearActive(); }), size: 42),
            ]),
            const SizedBox(height: 15),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 7,
              children: [for (var digit = 0; digit <= 9; digit++)
                SizedBox(width: (width - 4 * 8) / 5, height: 45,
                  child: ChunkyButton(onPressed: reported || _engine.isFailed
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
      ));
    }),
  );
}
