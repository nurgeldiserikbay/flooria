import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'mirror_beam_engine.dart';

const _palette = GamePalette(ground: Color(0xFFFFF2D9), surface: Colors.white,
  ink: Color(0xFF5B4937), muted: Color(0xFF9B8468), accent: Color(0xFFF0A943), edge: Color(0xFF5B4937));

Widget buildMirrorBeamPage(BuildContext context, GameLaunch launch) => MirrorBeamPage(launch: launch);

class MirrorBeamPage extends StatefulWidget {
  const MirrorBeamPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<MirrorBeamPage> createState() => _MirrorBeamPageState();
}

class _MirrorBeamPageState extends State<MirrorBeamPage> with LevelFlow<MirrorBeamPage> {
  late MirrorBeamEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = MirrorBeamEngine.forLevel(level);

  void _rotate(int cell) {
    final result = _engine.rotate(cell);
    if (result == MirrorBeamResult.ignored) return;
    setState(() {});
    HapticFeedback.selectionClick();
    if (result == MirrorBeamResult.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
    palette: _palette, title: 'Mirror Beam', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart',
      palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 36, box.maxHeight - (reported ? 340 : 250)).clamp(220.0, 350.0).toDouble();
      final lit = _engine.beamCells.toSet();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const HintLine('TURN THE MIRRORS · GUIDE THE BEAM', palette: _palette),
        Container(width: side, height: side, padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: const Color(0xFFE9D7B8), borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _palette.edge, width: 2), boxShadow: const [BoxShadow(color: Color(0xFFBDA783), offset: Offset(0, 5))]),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 25,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemBuilder: (context, cell) {
              final isMirror = _engine.mirrors.containsKey(cell);
              final slash = _engine.mirrors[cell];
              return GestureDetector(onTap: isMirror && !reported ? () => _rotate(cell) : null,
                child: AnimatedContainer(duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(color: lit.contains(cell) ? const Color(0xFFFFD45D) : const Color(0xFFFFFAEF),
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: _palette.edge.withValues(alpha: .25))),
                  child: Center(child: cell == MirrorBeamEngine.emitter
                    ? const Icon(Icons.flash_on_rounded, color: Color(0xFFEF8841), size: 27)
                    : cell == MirrorBeamEngine.receiver
                      ? Icon(Icons.adjust_rounded, color: lit.contains(cell) ? Colors.deepOrange : const Color(0xFF5EAA8B), size: 26)
                      : isMirror ? Text(slash! ? '/' : r'\', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF66543E)))
                      : null),
                ));
            })),
        const SizedBox(height: 14),
        if (reported)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: LevelResultPanel(palette: _palette,
            launch: launch, level: level, stars: _engine.rotations <= 2 ? 3 : 2,
            detail: 'The beam reached the receiver.', onReplay: replayLevel, onNext: nextLevel))
        else
          StatChip(label: 'MIRROR TURNS', value: _engine.rotations.toString(), palette: _palette),
      ]));
    }),
  );
}
