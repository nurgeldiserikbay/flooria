import 'package:flutter/material.dart';

import 'gear_works_engine.dart';

/// Standalone mechanical puzzle. Integration/persistence stays in app shell.
class GearWorksPage extends StatefulWidget {
  const GearWorksPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int moves, int gearsUsed) onSessionEnd;

  @override
  State<GearWorksPage> createState() => _GearWorksPageState();
}

class _GearWorksPageState extends State<GearWorksPage> {
  late GearWorksSession game;
  int revision = 0;
  bool rewarded = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = GearWorksSession(
      seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 12497 + revision);
    rewarded = false;
  }

  void _tap(int index) {
    if (rewarded || !game.toggle(index)) return;
    setState(() {});
    if (!game.complete) return;
    rewarded = true;
    widget.onSessionEnd(game.moves, game.placedGears.length);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF344D7C);
    final spinning = game.spinDirections;
    return Scaffold(
      backgroundColor: const Color(0xFFE7F4FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF4FAFF),
        foregroundColor: navy,
        title: const Text('Gear Works',
          style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900, color: Color(0xFF6E83A5))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFCBEFF9), Color(0xFFE2E5FF),
              Color(0xFFFFE9D9)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.settings_suggest_rounded,
                color: Color(0xFF7385BC), size: 24),
              const SizedBox(width: 7),
              const Expanded(child: Text('Connect the motor to the star',
                style: TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 13, color: navy))),
              Text('${game.remaining} left',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 12, color: Color(0xFF6B75A7))),
            ]),
            const SizedBox(height: 7),
            const Text('Tap spaces to place gears. Each gear turns its neighbors.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6880A7))),
            const SizedBox(height: 10),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final size = bounds.biggest.shortestSide.clamp(0.0, 432.0).toDouble();
              return Center(child: Container(
                width: size, height: size,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFB7C8E9), width: 2),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: game.size,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5),
                  itemCount: game.size * game.size,
                  itemBuilder: (context, index) {
                    final isDriver = index == game.driver;
                    final isReceiver = index == game.receiver;
                    final locked = game.fixedGears.contains(index);
                    final occupied = game.placedGears.contains(index);
                    final blocked = game.blockers.contains(index);
                    final gear = isDriver || isReceiver || locked || occupied;
                    final powered = spinning.containsKey(index);
                    final hue = isDriver
                      ? const Color(0xFF9DDED5)
                      : isReceiver
                        ? const Color(0xFFFFE4AB)
                        : powered
                          ? const Color(0xFFC5E8FB)
                          : gear
                            ? const Color(0xFFDAD7F8)
                            : blocked
                              ? const Color(0xFFCED3E4)
                              : const Color(0xFFEBF1FB);
                    return Semantics(
                      button: !blocked && !locked && !isDriver && !isReceiver,
                      label: isDriver ? 'Motor'
                        : isReceiver ? 'Target gear'
                        : blocked ? 'Obstacle'
                        : locked ? 'Fixed gear'
                        : occupied ? 'Remove gear'
                        : 'Place gear',
                      child: Material(
                        color: hue,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          key: ValueKey('gear-cell-$index'),
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => _tap(index),
                          child: Center(child: blocked
                            ? const Icon(Icons.close_rounded,
                                color: Color(0xFF9DA7C0), size: 24)
                            : gear
                              ? Stack(alignment: Alignment.center, children: [
                                  Icon(Icons.settings_rounded,
                                    color: powered
                                      ? const Color(0xFF478DB3)
                                      : const Color(0xFF7B79AF),
                                    size: size < 300 ? 32 : 42),
                                  Icon(isDriver ? Icons.bolt_rounded
                                    : isReceiver ? Icons.star_rounded
                                    : spinning[index] == -1
                                      ? Icons.keyboard_arrow_left_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                    color: isDriver
                                      ? const Color(0xFFFFD25E)
                                      : isReceiver
                                        ? const Color(0xFFE3A952)
                                        : const Color(0xFFEDF8FF),
                                    size: size < 300 ? 17 : 23),
                                ])
                              : const Icon(Icons.add_rounded,
                                  size: 19, color: Color(0xFFB5C4DF))),
                        ),
                      ),
                    );
                  },
                ),
              ));
            })),
            const SizedBox(height: 8),
            if (game.complete)
              const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Text('The gears are turning! Goal reached.',
                  style: TextStyle(color: Color(0xFF328C86),
                    fontWeight: FontWeight.w900, fontSize: 13)))
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Text('Blue gears are powered by the motor.',
                  style: TextStyle(color: Color(0xFF63799B), fontSize: 12))),
            Row(children: [
              Expanded(child: Text('${game.moves} moves',
                style: const TextStyle(color: navy,
                  fontWeight: FontWeight.w900, fontSize: 13))),
              FilledButton.icon(
                onPressed: () => setState(() {
                  revision++;
                  _reset();
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD68D),
                  foregroundColor: navy,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.complete ? 'NEW PUZZLE' : 'RESTART')),
            ]),
          ]),
        ),
      ))),
    );
  }
}
