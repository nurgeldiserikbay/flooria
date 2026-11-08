import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'tower_shift_engine.dart';

const _palette = GamePalette(
  ground: Color(0xFFEAF1FF), surface: Colors.white, ink: Color(0xFF283A67),
  muted: Color(0xFF7786AA), accent: Color(0xFF6675D9), edge: Color(0xFF283A67),
);
const _diskColors = [
  Color(0xFFFF8C72), Color(0xFFFFBC55), Color(0xFF6BC6A5),
  Color(0xFF5EA7DF), Color(0xFF9A83DF), Color(0xFFE778A2),
  Color(0xFF79B968),
];

Widget buildTowerShiftPage(BuildContext context, GameLaunch launch) =>
    TowerShiftPage(launch: launch);

class TowerShiftPage extends StatefulWidget {
  const TowerShiftPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<TowerShiftPage> createState() => _TowerShiftPageState();
}

class _TowerShiftPageState extends State<TowerShiftPage>
    with LevelFlow<TowerShiftPage> {
  late TowerShiftEngine _engine;
  bool _blocked = false;
  int _blockedPulse = 0;
  String _feedback = 'PICK A PEG, THEN CHOOSE A DESTINATION';

  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = TowerShiftEngine.forLevel(level);
    _blocked = false;
    _blockedPulse = 0;
    _feedback = 'PICK A PEG, THEN CHOOSE A DESTINATION';
  }

  void _tapPeg(int peg) {
    final result = _engine.tapPeg(peg);
    if (result == TowerMove.ignored) {
      setState(() => _feedback = 'CHOOSE A PEG WITH DISKS');
      return;
    }
    setState(() {
      _blocked = result == TowerMove.blocked;
      if (_blocked) _blockedPulse++;
      _feedback = switch (result) {
        TowerMove.selected => 'PEG ${['A', 'B', 'C'][peg]} SELECTED · CHOOSE A HIGHLIGHTED PEG',
        TowerMove.deselected => 'SELECTION CLEARED · PICK A PEG',
        TowerMove.moved => 'GOOD MOVE · ${_engine.moves} MOVES USED',
        TowerMove.blocked => 'BLOCKED · A BIGGER DISK CANNOT GO ON A SMALLER ONE',
        TowerMove.completed => 'ALL DISKS ON PEG C · PUZZLE SOLVED!',
        TowerMove.ignored => _feedback,
      };
    });
    if (result == TowerMove.blocked) {
      HapticFeedback.selectionClick();
    } else if (result == TowerMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: {'planning': _engine.planningMetric});
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette,
    title: 'Tower Shift',
    level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, constraints) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final motion = reduceMotion
          ? Duration.zero : const Duration(milliseconds: 170);
      final diskHeight = min(30.0,
          max(18.0, (constraints.maxHeight - 190) / (_engine.disks + 2)))
          .toDouble();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            StatChip(label: 'MOVES', value: '${_engine.moves}', palette: _palette),
            StatChip(label: 'PAR', value: '${_engine.par}', palette: _palette),
            StatChip(label: 'DISKS', value: '${_engine.disks}', palette: _palette),
          ]),
          const SizedBox(height: 16),
          Expanded(child: Semantics(
            key: const ValueKey('tower-board-state'),
            label: '${_engine.pegs[2].length} of ${_engine.disks} disks on goal peg C. '
                '${_engine.moves} moves made. '
                '${_engine.selectedPeg == null ? 'No peg selected' : 'Peg ${['A', 'B', 'C'][_engine.selectedPeg!]} selected'}.',
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (peg) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PegCard(
                peg: peg,
                disks: _engine.pegs[peg],
                diskCount: _engine.disks,
                diskHeight: diskHeight,
                selected: _engine.selectedPeg == peg,
                legalTarget: _engine.selectedPeg != null &&
                    _engine.selectedPeg != peg &&
                    (_engine.pegs[peg].isEmpty ||
                        _engine.pegs[peg].last >
                            _engine.pegs[_engine.selectedPeg!].last),
                blocked: _blocked,
                motion: motion,
                onTap: () => _tapPeg(peg),
              ),
            )))),
          )),
          const SizedBox(height: 12),
          Shake(
            trigger: _blockedPulse,
            child: HintLine(
              _feedback,
              palette: _palette,
              leading: Icon(Icons.touch_app_rounded,
                size: 16, color: _palette.accent),
            ),
          ),
          if (reported) ...[
            const SizedBox(height: 8),
            LevelResultPanel(
              palette: _palette, launch: launch, level: level,
              stars: _engine.moves <= _engine.par
                  ? 3 : _engine.moves <= _engine.par + 4 ? 2 : 1,
              detail: '${_engine.moves} moves · best is ${_engine.par}.',
              onReplay: replayLevel, onNext: nextLevel,
            ),
          ],
        ]),
      );
    }),
  );
}

class _PegCard extends StatelessWidget {
  const _PegCard({required this.peg, required this.disks,
    required this.diskCount, required this.diskHeight, required this.selected,
    required this.blocked, required this.legalTarget,
    required this.motion, required this.onTap});

  final int peg;
  final List<int> disks;
  final int diskCount;
  final double diskHeight;
  final bool selected, blocked, legalTarget;
  final Duration motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('tower-peg-$peg'),
    button: true,
    selected: selected,
    label: 'Peg ${['A', 'B', 'C'][peg]}, '
        '${disks.length} disks'
        '${selected ? ', selected' : ''}'
        '${legalTarget ? ', valid destination' : ''}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? const [Color(0xFFE9EAFF), Color(0xFFD4D9FF)]
                  : legalTarget
                      ? const [Color(0xFFE7FAF0), Color(0xFFCAF1DF)]
                      : const [Colors.white, Color(0xFFF4F7FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _palette.accent
                  : legalTarget ? const Color(0xFF4DAE88)
                  : const Color(0xFFD8DFF0),
              width: selected || legalTarget ? 2 : 1,
            ),
            boxShadow: legalTarget ? const [
              BoxShadow(color: Color(0x254DAE88),
                blurRadius: 8, offset: Offset(0, 2)),
            ] : null,
          ),
        child: LayoutBuilder(builder: (context, box) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(bottom: 18, child: Container(
              width: 7,
              height: box.maxHeight * .66,
              decoration: BoxDecoration(color: const Color(0xFFB9C4DF),
                borderRadius: BorderRadius.circular(5)),
            )),
            Positioned(bottom: 10, left: 4, right: 4,
              child: Column(mainAxisSize: MainAxisSize.min,
                children: disks.reversed.map((disk) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: (box.maxWidth - 12) * (.38 + .62 * disk / diskCount),
                    height: diskHeight,
                    decoration: BoxDecoration(
                      color: _diskColors[(disk - 1) % _diskColors.length],
                      borderRadius: BorderRadius.circular(diskHeight / 2),
                      border: Border.all(color: Colors.white.withValues(alpha: .8), width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x22304268),
                        offset: Offset(0, 2), blurRadius: 2)],
                    ),
                  ),
                )).toList(),
              ),
            ),
            Positioned(top: 10, child: Text(['A', 'B', 'C'][peg],
              style: TextStyle(color: selected ? _palette.accent : _palette.muted,
                fontSize: 12, fontWeight: FontWeight.w900))),
            if (peg == 2) const Positioned(bottom: 2, child: Icon(
              Icons.flag_rounded, size: 15, color: Color(0xFF4DAE88))),
            if (legalTarget) const Positioned(top: 8, right: 8,
              child: Icon(Icons.check_circle_rounded,
                size: 16, color: Color(0xFF4DAE88))),
            if (blocked && selected) const Positioned(top: 8, left: 8,
              child: Icon(Icons.close_rounded, size: 15, color: Color(0xFFE36C72))),
          ],
        )),
        ),
      ),
    ),
  );
}
