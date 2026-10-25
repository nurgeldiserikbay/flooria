import 'package:flutter/material.dart';
import '../game/light_grid.dart';
import 'floor_victory.dart';

/// Independent logic mini-game; layout and engine are isolated from the hub.
class LightGridPage extends StatefulWidget {
  const LightGridPage({
    super.key, this.floor, required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int moves) onSessionEnd;

  @override
  State<LightGridPage> createState() => _LightGridPageState();
}

class _LightGridPageState extends State<LightGridPage> {
  late LightGridSession session;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = LightGridSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 1499 + revision,
      scrambleCount: 4 + ((widget.floor ?? 1) ~/ 24).clamp(0, 3));
    reported = false;
  }

  Future<void> _tap(int index) async {
    if (reported) return;
    if (!session.tap(index)) return;
    setState(() {});
    if (!session.finished) return;
    reported = true;
    widget.onSessionEnd(session.moves);
    if (widget.floor == null) return;
    widget.onComplete();
    final result = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'All lights switched off in ${session.moves} moves!',
      detail: 'You have activated the next neuron.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(result == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE2EAF9),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Light Grid',
        style: TextStyle(fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFEFF4FF),
      foregroundColor: const Color(0xFF465E92),
      actions: [
        if (widget.floor != null)
          Center(child: Padding(padding: const EdgeInsets.only(right: 18),
            child: Text('LEVEL ${widget.floor}',
              style: const TextStyle(color: Color(0xFF748BB5),
                fontSize: 12, fontWeight: FontWeight.w900)))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFC4DCFF), Color(0xFFE6E1FA), Color(0xFFDEFAEF)])),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded,
              color: Color(0xFFD2994B), size: 23),
            const SizedBox(width: 9),
            const Expanded(child: Text('Turn off all the lights',
              style: TextStyle(color: Color(0xFF3A548D),
                fontSize: 14, fontWeight: FontWeight.w900))),
            Text('${session.litCount} lit', style: const TextStyle(
              color: Color(0xFF6D6ABD), fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 9),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final size = bounds.biggest.shortestSide.clamp(0.0, 430.0).toDouble();
            return Center(child: SizedBox.square(
              dimension: size,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 11, crossAxisSpacing: 11),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final on = session.lights[index];
                  return Semantics(
                    button: true,
                    label: 'Light ${index + 1}, ${on ? "on" : "off"}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: reported ? null : () => _tap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: on
                            ? [const Color(0xFFFFEEA5), const Color(0xFFFFBF70)]
                            : [const Color(0xFFE6EBFC), const Color(0xFFB7C7E7)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: on ? const Color(0xFFFFF5CF)
                              : const Color(0xFFFFFFFF), width: 2),
                          boxShadow: on ? const [BoxShadow(
                            color: Color(0x77FFD47A), blurRadius: 18)]
                            : null),
                        child: Icon(
                          on ? Icons.wb_incandescent_rounded
                            : Icons.circle_outlined,
                          size: size * .12,
                          color: on ? const Color(0xFFCE8A3F)
                            : const Color(0xFF879BCC)),
                      ),
                    ),
                  );
                },
              ),
            ));
          })),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('${session.moves} moves',
              style: const TextStyle(color: Color(0xFF6C7FA5),
                fontWeight: FontWeight.w900, fontSize: 13))),
            FilledButton.icon(
              onPressed: () => setState(() {
                revision++;
                _restart();
              }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD788),
                foregroundColor: const Color(0xFF564776)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RESTART')),
          ]),
        ]),
      ),
    ))),
  );
}
