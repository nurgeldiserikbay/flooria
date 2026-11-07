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
  int _blockedPulse = 0;
  @override
  GameLaunch get launch => widget.launch;
  @override
  void initState() { super.initState(); resetLevel(); }
  @override
  void resetLevel() {
    _engine = MagneticRoomEngine.forLevel(level);
    _blockedPulse = 0;
  }

  void _pulse(MagnetDirection direction) {
    final result = _engine.pulse(direction);
    if (result == MagnetMove.ignored) return;
    if (result == MagnetMove.blocked) {
      HapticFeedback.selectionClick();
      setState(() => _blockedPulse++);
      return;
    }
    setState(() {});
    if (result == MagnetMove.completed) {
      HapticFeedback.mediumImpact();
      reportWin(score: _engine.score, metrics: const {});
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(palette: _palette, title: 'Magnetic Room', level: level,
    actions: [ChunkyIconButton(icon: Icons.refresh_rounded, tooltip: 'Restart', palette: _palette, onPressed: reported ? null : replayLevel)],
    child: LayoutBuilder(builder: (context, box) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final duration =
          reduceMotion ? Duration.zero : const Duration(milliseconds: 190);
      final side = math.min(box.maxWidth - 34, box.maxHeight - (reported ? 350 : 300)).clamp(220.0, 350.0).toDouble();
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(label: 'PULSES', value: _engine.pulses.toString(), palette: _palette),
          const Icon(Icons.electric_bolt_rounded, color: Color(0xFF8172D4), size: 25),
          StatChip(label: 'METAL', value: '×2', palette: _palette),
        ])),
        const SizedBox(height: 9),
        Container(
          width: side, height: side,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFE4E0FA),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFC9C1E8)),
            boxShadow: const [
              BoxShadow(color: Color(0x28514A78),
                blurRadius: 16, offset: Offset(0, 5)),
            ],
          ),
          child: GridView.builder(
            key: const ValueKey('magnet-board'),
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: MagneticRoomEngine.side * MagneticRoomEngine.side,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MagneticRoomEngine.side,
              crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, cell) {
              final wall = _engine.walls.contains(cell);
              final metal = _engine.metal.contains(cell);
              final player = cell == _engine.position;
              final goal = cell == _engine.goal;
              return Semantics(
                key: ValueKey('magnet-cell-$cell'),
                label: 'Row ${cell ~/ MagneticRoomEngine.side + 1}, '
                    'column ${cell % MagneticRoomEngine.side + 1}, '
                    '${wall ? 'wall' : metal ? 'magnetic plate' : 'floor'}'
                    '${player ? ', core' : ''}'
                    '${goal ? ', socket' : ''}',
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: wall
                          ? const [Color(0xFFA9A5C4), Color(0xFF757295)]
                          : metal
                              ? const [
                                  Color(0xFFFFF0C8),
                                  Color(0xFFFFD785),
                                ]
                              : const [
                                  Colors.white,
                                  Color(0xFFF6F3FF),
                                ],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: player ? const Color(0xFF8172D4)
                          : metal ? const Color(0xFFE4C37E)
                          : const Color(0xFFE4DEEF),
                      width: player ? 2 : 1),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOutBack,
                    child: player
                        ? const Icon(
                            Icons.circle,
                            key: ValueKey('magnet-core'),
                            color: Color(0xFF8172D4), size: 25)
                        : goal
                            ? const Icon(Icons.adjust_rounded,
                                key: ValueKey('magnet-socket'),
                                color: Color(0xFF4BA981), size: 24)
                            : metal
                                ? const Icon(Icons.bolt_rounded,
                                    key: ValueKey('magnet-plate'),
                                    color: Color(0xFFAC7A26), size: 18)
                                : wall
                                    ? const Icon(Icons.square_rounded,
                                        key: ValueKey('magnet-wall'),
                                        color: Color(0xFF656383), size: 11)
                                    : const SizedBox.shrink(
                                        key: ValueKey('magnet-empty')),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        _MagnetPad(onPulse: _pulse, disabled: reported),
        if (reported) Padding(padding: const EdgeInsets.all(8), child: LevelResultPanel(palette: _palette, launch: launch,
          level: level, stars: _engine.pulses <= 12 ? 3 : 2, detail: 'Guided the core into the socket.', onReplay: replayLevel, onNext: nextLevel))
        else Shake(
          trigger: _blockedPulse,
          child: const HintLine(
            'METAL TILES CARRY THE PULSE TWO CELLS',
            palette: _palette),
        ),
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
