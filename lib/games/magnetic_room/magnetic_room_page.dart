import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/game_registry.dart';
import '../../ui/game_kit.dart';
import 'magnetic_room_engine.dart';

const _palette = GamePalette(ground: Color(0xFFF0EEFF), surface: Colors.white, ink: Color(0xFF514A78),
  muted: Color(0xFF8982AC), accent: Color(0xFF8172D4), edge: Color(0xFF514A78));
Widget buildMagneticRoomPage(BuildContext context, GameLaunch launch) => MagneticRoomPage(launch: launch);

class MagneticRoomPage extends StatefulWidget {
  const MagneticRoomPage({super.key, required this.launch});
  final GameLaunch launch;
  @override
  State<MagneticRoomPage> createState() => _MagneticRoomPageState();
}

class _MagneticRoomPageState extends State<MagneticRoomPage> with LevelFlow<MagneticRoomPage> {
  late MagneticRoomEngine _engine;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() => _engine = MagneticRoomEngine.forLevel(level);
  void _pulse(MagnetDirection d) {
    final result = _engine.pulse(d); setState(() {}); HapticFeedback.selectionClick();
    if (result == MagnetMove.completed) { HapticFeedback.mediumImpact(); reportWin(score: _engine.score, metrics: const {}); }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Magnetic Room', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported ? 350 : 300)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'PULSES', value: _engine.pulses.toString(), palette: _palette),
          const Icon(Icons.electric_bolt_rounded, color: Color(0xFF8172D4), size: 25),
          StatChip(label: 'METAL', value: '×2', palette: _palette),
        ])),
        const SizedBox(height: 9),
        Container(width: side, height: side, padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFDCD8F5),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: _palette.edge, width: 2)),
          child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 36,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) => Container(decoration: BoxDecoration(color: _engine.walls.contains(cell) ? const Color(0xFF8582A5) : Colors.white,
              borderRadius: BorderRadius.circular(7)), child: Center(child: cell == _engine.position
                ? const Icon(Icons.circle, color: Color(0xFF8070DB), size: 24)
                : cell == _engine.goal ? const Icon(Icons.adjust_rounded, color: Color(0xFF65B894), size: 23)
                : _engine.metal.contains(cell) ? const Icon(Icons.bolt_rounded, color: Color(0xFFE6B34F), size: 18)
                : _engine.walls.contains(cell) ? const Icon(Icons.square_rounded, color: Color(0xFF656383), size: 11) : null))),
        const SizedBox(height: 9),
        _MagnetPad(onPulse: _pulse, disabled: reported),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.pulses <= 12 ? 3 : 2, detail: 'Guided the core into the socket.', onReplay: replayLevel, onNext: nextLevel))
        else const HintLine('METAL TILES CARRY THE PULSE TWO CELLS', palette: _palette),
      ]));
    }));
}

class _MagnetPad extends StatelessWidget {
  const _MagnetPad({required this.onPulse, required this.disabled});
  final ValueChanged<MagnetDirection> onPulse; final bool disabled;
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3, children: [
      const SizedBox(), _button(Icons.keyboard_arrow_up_rounded, MagnetDirection.up), const SizedBox(),
      _button(Icons.keyboard_arrow_left_rounded, MagnetDirection.left), const Icon(Icons.add, color: Color(0xFF514A78)),
      _button(Icons.keyboard_arrow_right_rounded, MagnetDirection.right), const SizedBox(), _button(Icons.keyboard_arrow_down_rounded, MagnetDirection.down), const SizedBox(),
    ]));
  Widget _button(IconData icon, MagnetDirection d) => ChunkyIconButton(icon: icon, tooltip: 'Pulse ${d.name}', palette: _palette,
    onPressed: disabled ? null : () => onPulse(d));
}
