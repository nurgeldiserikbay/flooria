import 'package:flutter/material.dart';
import '../game/color_spot.dart';
import 'floor_victory.dart';

/// Fully self-contained visual puzzle with its own palette and feedback.
class ColorSpotPage extends StatefulWidget {
  const ColorSpotPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int correct, int total) onSessionEnd;

  @override
  State<ColorSpotPage> createState() => _ColorSpotPageState();
}

class _ColorSpotPageState extends State<ColorSpotPage> {
  late ColorSpotSession session;
  int revision = 0;
  int? selection;
  bool? wasCorrect;
  bool busy = false;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = ColorSpotSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 1301 + revision);
    selection = null;
    wasCorrect = null;
    busy = false;
    reported = false;
  }

  Future<void> _choose(int index) async {
    if (busy || session.finished) return;
    final active = session;
    final hit = active.current.oddIndex == index;
    setState(() {
      busy = true;
      selection = index;
      wasCorrect = hit;
    });
    await Future<void>.delayed(const Duration(milliseconds: 440));
    if (!mounted || active != session) return;
    active.answer(index);
    setState(() {
      busy = false;
      selection = null;
      wasCorrect = null;
    });
    if (!active.finished || reported) return;
    reported = true;
    widget.onSessionEnd(active.correct, ColorSpotSession.roundCount);
    if (widget.floor == null || active.correct < 4) return;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: '${active.correct} of 5 colors found!',
      detail: 'A new challenge has opened in your network.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = session.finished ? null : session.current;
    return Scaffold(
      backgroundColor: const Color(0xFFE5F3F1),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Color Spot',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFEEF9F7),
        foregroundColor: const Color(0xFF2C5C6C),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                color: Color(0xFF548D97), fontWeight: FontWeight.w900,
                fontSize: 12)))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFB7EFE4), Color(0xFFDDF6E8), Color(0xFFFFE8DC)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.palette_rounded,
                color: Color(0xFF3B9E9E), size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Text('Find the different shade',
                style: TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 14, color: Color(0xFF2B626E)))),
              Text('${session.round.clamp(0, 5)} / 5',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF408B91))),
            ]),
            const SizedBox(height: 10),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final size = bounds.biggest.shortestSide.clamp(0.0, 440.0).toDouble();
              return Center(child: session.finished
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.stars_rounded,
                      size: 67, color: Color(0xFFEFB76B)),
                    const SizedBox(height: 11),
                    Text('${session.correct} / 5 correct',
                      style: const TextStyle(fontSize: 27,
                        color: Color(0xFF316C70),
                        fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(session.correct >= 4 ? 'Great eyes!' : 'Try again!',
                      style: const TextStyle(color: Color(0xFF648D8C))),
                  ])
                : SizedBox.square(
                    dimension: size,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: 9,
                      itemBuilder: (context, i) {
                        final picked = selection == i;
                        return Semantics(button: true,
                          label: 'Color tile ${i + 1}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19),
                            onTap: busy ? null : () => _choose(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: Color(puzzle!.colors[i]),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: picked ? Colors.white
                                    : const Color(0xAAFFFFFF),
                                  width: picked ? 5 : 2),
                                boxShadow: const [BoxShadow(
                                  color: Color(0x224B8E94), blurRadius: 8,
                                  offset: Offset(0, 4))]),
                              child: picked ? Icon(
                                wasCorrect == true
                                  ? Icons.check_circle_rounded
                                  : Icons.close_rounded,
                                color: Colors.white, size: 35) : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ));
            })),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${session.correct} correct',
                style: const TextStyle(color: Color(0xFF54858B),
                  fontSize: 13, fontWeight: FontWeight.w900))),
              FilledButton.icon(
                onPressed: () => setState(() { revision++; _restart(); }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD38E),
                  foregroundColor: const Color(0xFF346067)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RESTART')),
            ]),
          ]),
        ),
      ))),
    );
  }
}
