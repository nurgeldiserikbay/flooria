import 'package:flutter/material.dart';

import 'torch_bridge_engine.dart';

/// Independent crossing-puzzle UI. The shell owns persistence and tower flow.
class TorchBridgePage extends StatefulWidget {
  const TorchBridgePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int crossings, int mistakes) onSessionEnd;

  @override
  State<TorchBridgePage> createState() => _TorchBridgePageState();
}

class _TorchBridgePageState extends State<TorchBridgePage> {
  late TorchBridgeSession session;
  int revision = 0;
  int totalCrossings = 0;
  bool rewarded = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = TorchBridgeSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 9901 + revision,
    );
    totalCrossings = 0;
    rewarded = false;
  }

  void _toggle(int traveler) {
    if (rewarded || !session.toggle(traveler)) return;
    setState(() {});
  }

  void _cross() {
    if (rewarded || !session.cross()) return;
    totalCrossings++;
    setState(() {});
  }

  void _continue() {
    if (rewarded || !session.solved || session.outOfTime) return;
    final advanced = session.nextRound();
    if (!advanced) return;
    setState(() {});
    if (!session.complete) return;
    rewarded = true;
    widget.onSessionEnd(
      session.round, totalCrossings, session.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _person(int id) {
    final selected = session.selected.contains(id);
    const ink = Color(0xFF39537E);
    return InkWell(
      key: ValueKey('torch-traveler-$id'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _toggle(id),
      child: Container(
        height: 53,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD88B)
              : const Color(0xFFF9FCFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFE6AA50)
                : const Color(0xFFB2C7E4),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.person_rounded, color: Color(0xFF778ABF), size: 20),
          const SizedBox(width: 3),
          Text('${session.travelerTimes[id]}m',
            style: const TextStyle(color: ink, fontSize: 13,
                fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _bank(bool farBank) {
    final travelers = [
      for (var id = 0; id < TorchBridgeSession.travelerCount; id++)
        if (session.isAcross(id) == farBank) id,
    ];
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xC9FFFFFF),
        border: Border.all(color: const Color(0xFFB8C9E8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(farBank ? 'FAR SIDE' : 'START',
            style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w900, color: Color(0xFF526B99))),
          if (session.torchAcross == farBank)
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flashlight_on_rounded, size: 16,
                color: Color(0xFFE19B3B)),
              Text(' TORCH', style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w900, color: Color(0xFFA47A41))),
            ]),
        ]),
        const SizedBox(height: 8),
        if (travelers.isEmpty)
          const Expanded(child: Center(child: Text('No travelers',
            style: TextStyle(fontSize: 11, color: Color(0xFF8A9BBB)))))
        else
          Expanded(child: LayoutBuilder(builder: (context, box) {
            return Center(child: Wrap(
              spacing: 7, runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [for (final id in travelers)
                SizedBox(width: (box.maxWidth - 14) / 2, child: _person(id))],
            ));
          })),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF39537E);
    final solved = session.solved && !session.outOfTime;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FC),
      appBar: AppBar(
        title: const Text('Torch Bridge',
          style: TextStyle(fontWeight: FontWeight.w900)),
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF4FAFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7487A8))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFC7E9F8), Color(0xFFE7E5FC),
              Color(0xFFFFECDD)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.flashlight_on_rounded,
                color: Color(0xFFF2AA48)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Get everyone across!',
                style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w900, color: ink))),
              Text('${session.round} / ${session.roundCount}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF687BAB))),
            ]),
            const SizedBox(height: 8),
            Text('Time ${session.elapsed} / ${session.timeLimit} min',
              key: const ValueKey('torch-time'),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900,
                color: session.outOfTime
                  ? const Color(0xFFB45F76) : ink)),
            const SizedBox(height: 4),
            const Text('Select 1 or 2 people. A crossing takes the slower time.',
              style: TextStyle(fontSize: 11, color: Color(0xFF61769D)),
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Expanded(child: Column(children: [
              Expanded(child: _bank(false)),
              SizedBox(height: 82, child: Center(child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(height: 13, margin: const EdgeInsets.symmetric(
                    horizontal: 13), decoration: BoxDecoration(
                      color: const Color(0xFF8BA9CE),
                      borderRadius: BorderRadius.circular(10))),
                  Container(
                    width: 116, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FCFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF9CB9DB),
                        width: 2)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(session.torchAcross
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                          size: 24, color: const Color(0xFF677CB0)),
                        const SizedBox(width: 3),
                        const Text('BRIDGE', style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13, color: ink)),
                      ]),
                  ),
                ],
              ))),
              Expanded(child: _bank(true)),
            ])),
            const SizedBox(height: 9),
            if (session.outOfTime)
              const Text('Too slow! Restart and try another route.',
                style: TextStyle(color: Color(0xFFAB6179),
                  fontSize: 12, fontWeight: FontWeight.w800))
            else if (solved)
              const Text('Everyone is safe! Great planning.',
                style: TextStyle(color: Color(0xFF388F82),
                  fontSize: 12, fontWeight: FontWeight.w900))
            else
              Text('${session.selected.length}/2 selected',
                style: const TextStyle(color: Color(0xFF6076A0),
                  fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('$totalCrossings crossings',
                style: const TextStyle(color: ink, fontSize: 12,
                  fontWeight: FontWeight.w900))),
              FilledButton.icon(
                key: const ValueKey('torch-action'),
                onPressed: session.complete
                  ? () => setState(() {
                      revision++;
                      _restart();
                    })
                  : solved ? _continue
                    : session.canCross ? _cross : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7879C7),
                  foregroundColor: Colors.white),
                icon: Icon(session.complete ? Icons.refresh_rounded
                  : solved ? Icons.arrow_forward_rounded
                  : Icons.swap_vert_rounded),
                label: Text(session.complete ? 'PLAY AGAIN'
                  : solved ? 'NEXT' : 'CROSS'),
              ),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() {
                  revision++;
                  _restart();
                }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
          ]),
        ),
      ))),
    );
  }
}
