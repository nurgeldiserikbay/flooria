import 'package:flutter/material.dart';
import 'river_crossing_engine.dart';

class RiverCrossingPage extends StatefulWidget {
  const RiverCrossingPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int invalidMoves) onSessionEnd;

  @override
  State<RiverCrossingPage> createState() => _RiverCrossingPageState();
}

class _RiverCrossingPageState extends State<RiverCrossingPage> {
  late RiverCrossingSession game;
  int revision = 0;
  bool rewarded = false;
  bool unsafe = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = RiverCrossingSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1009 + revision,
    );
    rewarded = false;
    unsafe = false;
  }

  void _select(int i) {
    if (rewarded || !game.toggle(i)) return;
    setState(() => unsafe = false);
  }

  void _cross() {
    if (rewarded) return;
    final moved = game.cross();
    setState(() => unsafe = !moved);
    if (!moved || !game.complete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(game.round, game.totalMoves, game.invalidMoves);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _bank(int bank) {
    final here = [
      for (var i = 0; i < game.passengers.length; i++)
        if (game.bankOf(i) == bank) i,
    ];
    return Expanded(child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bank == 0
            ? const Color(0xFFE3F4D9) : const Color(0xFFFFE9CA),
        border: Border.all(color: const Color(0xFFB3C8BA), width: 2),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(children: [
        Text(bank == 0 ? 'LEFT BANK' : 'RIGHT BANK',
          style: const TextStyle(color: Color(0xFF48668A),
            fontWeight: FontWeight.w900, fontSize: 11)),
        const SizedBox(height: 9),
        for (final i in here)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: SizedBox(height: 42, width: double.infinity,
              child: FilledButton(
                key: ValueKey('river-passenger-$i'),
                onPressed: game.boatBank != bank ? null : () => _select(i),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  foregroundColor: const Color(0xFF405B80),
                  backgroundColor: game.selected.contains(i)
                      ? const Color(0xFFB7B2F5)
                      : const Color(0xFFFFFFFF),
                  disabledBackgroundColor: const Color(0xF3FFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: Text(game.passengers[i],
                  style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        const Spacer(),
        if (game.boatBank == bank)
          const Icon(Icons.directions_boat_rounded,
            color: Color(0xFF667DB3), size: 33),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF354C7A);
    return Scaffold(
      backgroundColor: const Color(0xFFECF6FE),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('River Crossing',
          style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF7FAFF),
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 14),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(color: Color(0xFF6E81A9),
                  fontWeight: FontWeight.w900, fontSize: 12)))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFCDEDFB), Color(0xFFE4E2FA),
              Color(0xFFFFECD9)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.sailing_rounded,
                color: Color(0xFF7589C0)),
              const SizedBox(width: 7),
              const Expanded(child: Text('Get everyone across safely',
                style: TextStyle(color: ink,
                  fontSize: 13, fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF6E79AE),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 7),
            const Text('Choose passengers on the boat side, then CROSS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6279A3), fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xF6FFFFFF),
                borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const Text('DO NOT LEAVE THESE PAIRS ALONE',
                  style: TextStyle(color: ink,
                    fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(game.forbidden.map((pair) =>
                  '${game.passengers[pair.$1]} + ${game.passengers[pair.$2]}'
                ).join('  •  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94677B),
                    fontWeight: FontWeight.w800, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 9),
            Expanded(child: Row(children: [
              _bank(0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_rounded,
                      color: Color(0xFF79BDDA), size: 26),
                    const SizedBox(height: 5),
                    Text(game.boatBank == 0 ? '→' : '←',
                      style: const TextStyle(
                        fontSize: 24, color: Color(0xFF618AAE))),
                    const SizedBox(height: 5),
                    Text('${game.selected.length}/${game.capacity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12,
                        color: ink)),
                  ],
                )),
              _bank(1),
            ])),
            const SizedBox(height: 9),
            Text(game.complete
                ? 'Everyone crossed safely!'
                : unsafe
                    ? 'Unsafe crossing! Change your passengers.'
                    : 'You may send the boat back empty if safe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: unsafe
                  ? const Color(0xFFB45E6C) : ink,
                fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${game.totalMoves} crossings',
                style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 12))),
              FilledButton.icon(
                key: const ValueKey('river-cross-button'),
                onPressed: game.complete
                    ? () => setState(() { revision++; _reset(); })
                    : _cross,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7878C8),
                  foregroundColor: Colors.white),
                icon: Icon(game.complete
                    ? Icons.refresh_rounded : Icons.sailing_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'CROSS'),
              ),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() { revision++; _reset(); }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
          ]),
        ),
      ))),
    );
  }
}
