import 'package:flutter/material.dart';
import '../game/tap_sprint.dart';
import 'floor_victory.dart';

/// Separate timing and reflex module; no shared game-state dependencies.
class TapSprintPage extends StatefulWidget {
  const TapSprintPage({
    super.key, this.floor, required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int elapsedMillis, int mistakes) onSessionEnd;

  @override
  State<TapSprintPage> createState() => _TapSprintPageState();
}

class _TapSprintPageState extends State<TapSprintPage> {
  late TapSprintSession session;
  Stopwatch clock = Stopwatch();
  int revision = 0;
  bool rewarded = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    clock.stop();
    clock = Stopwatch();
    session = TapSprintSession(
      seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 691 + revision);
    rewarded = false;
  }

  Future<void> _tap(int index) async {
    if (rewarded || session.finished) return;
    if (session.expected == 1 && !clock.isRunning) clock.start();
    setState(() { session.tap(index); });
    if (!session.finished) return;
    clock.stop();
    rewarded = true;
    widget.onSessionEnd(clock.elapsedMilliseconds, session.mistakes);
    if (widget.floor == null) return;
    widget.onComplete();
    final result = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'All nine numbers found!',
      detail: 'Your next neuron has opened.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(result == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFEED6),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Tap Sprint', style: TextStyle(
        fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFFFF4E5),
      foregroundColor: const Color(0xFF76513D),
      actions: [
        if (widget.floor != null)
          Center(child: Padding(padding: const EdgeInsets.only(right: 18),
            child: Text('LEVEL ${widget.floor}', style: const TextStyle(
              color: Color(0xFFAD8066), fontSize: 12,
              fontWeight: FontWeight.w900)))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFD4A8), Color(0xFFFFE8CF), Color(0xFFF2D7EF)])),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.flash_on_rounded,
              color: Color(0xFFEA874C), size: 23),
            const SizedBox(width: 8),
            const Expanded(child: Text('Tap numbers from 1 to 9',
              style: TextStyle(fontWeight: FontWeight.w900,
                fontSize: 14, color: Color(0xFF815747)))),
            Text('${session.completed} / 9', style: const TextStyle(
              color: Color(0xFFC07253), fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final width = bounds.biggest.shortestSide.clamp(0.0, 430.0).toDouble();
            return Center(child: SizedBox.square(
              dimension: width,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final value = session.values[index];
                  final cleared = value < session.expected;
                  return Semantics(button: true,
                    label: cleared ? '$value complete' : 'Number $value',
                    child: Material(
                      color: cleared
                        ? const Color(0xAAFFFFFF)
                        : const Color(0xFFFFFBF7),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: cleared ? null : () => _tap(index),
                        child: Center(child: cleared
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF81BAA0), size: 32)
                          : Text('$value', style: const TextStyle(
                              fontSize: 35, fontWeight: FontWeight.w900,
                              color: Color(0xFFC47959)))),
                      ),
                    ),
                  );
                },
              ),
            ));
          })),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: Text(session.finished
              ? '${(clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} s'
              : '${session.mistakes} missed taps',
              style: const TextStyle(fontWeight: FontWeight.w800,
                color: Color(0xFF936D65), fontSize: 13))),
            FilledButton.icon(
              onPressed: () => setState(() {
                revision++;
                _restart();
              }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFF8EA),
                foregroundColor: const Color(0xFFA66243)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RESTART')),
          ]),
        ]),
      ),
    ))),
  );

  @override
  void dispose() {
    clock.stop();
    super.dispose();
  }
}
