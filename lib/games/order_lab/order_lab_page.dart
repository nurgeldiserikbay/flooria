import 'package:flutter/material.dart';
import 'order_lab_engine.dart';

class OrderLabPage extends StatefulWidget {
  const OrderLabPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int swaps, int mistakes) onSessionEnd;

  @override
  State<OrderLabPage> createState() => _OrderLabPageState();
}

class _OrderLabPageState extends State<OrderLabPage> {
  late OrderLabSession session;
  int revision = 0;
  bool reported = false;
  bool wrong = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    session = OrderLabSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 2027 + revision);
    reported = false;
    wrong = false;
  }

  void _tap(int i) {
    if (reported || !session.tap(i)) return;
    setState(() => wrong = false);
  }

  void _check() {
    if (reported) return;
    final right = session.check();
    setState(() => wrong = !right);
    if (!session.complete || reported) return;
    reported = true;
    widget.onSessionEnd(session.round, session.swaps, session.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF334E78);
    const fills = [
      Color(0xFFFAADAA), Color(0xFF92DAC7),
      Color(0xFFC9B5F6), Color(0xFFFFDA98), Color(0xFFA4C8F4),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        title: const Text('Order Lab',
          style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7284AA))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFD0EBFB), Color(0xFFE4E1FB),
              Color(0xFFFFECDD)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.format_list_numbered_rounded,
                color: Color(0xFF8079BF)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Find the secret order',
                style: TextStyle(color: ink, fontWeight: FontWeight.w900,
                  fontSize: 14))),
              Text('${session.round} / ${session.roundCount}',
                style: const TextStyle(color: Color(0xFF7784AC),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 9),
            const Text('Tap two tiles to swap their places.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF61799F))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xF5FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFCBE6))),
              child: Row(children: [
                for (var i = 0; i < session.order.length; i++)
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: fills[session.order[i]],
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        key: ValueKey('order-tile-$i'),
                        borderRadius: BorderRadius.circular(13),
                        onTap: session.complete ? null : () => _tap(i),
                        child: Container(
                          height: 65,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: session.selected == i ? 3 : 1,
                              color: session.selected == i
                                ? const Color(0xFF6657AE)
                                : const Color(0xFF9EADCA)),
                            borderRadius: BorderRadius.circular(13)),
                          child: Text(String.fromCharCode(
                              65 + session.order[i]),
                            style: const TextStyle(color: ink,
                              fontSize: 23, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  )),
              ]),
            ),
            const SizedBox(height: 11),
            Expanded(child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xF5FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC5D3EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLUES', style: TextStyle(
                    fontSize: 13, color: ink,
                    fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.clues.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                          size: 18, color: Color(0xFF7D8BBC)),
                        const SizedBox(width: 7),
                        Expanded(child: Text(session.clues[i].describe(),
                          style: const TextStyle(
                            color: ink, fontWeight: FontWeight.w800,
                            fontSize: 13))),
                      ]),
                    ),
                  )),
                ],
              ),
            )),
            const SizedBox(height: 10),
            Text(session.complete
                ? 'You solved every sequence!'
                : wrong ? 'Not yet. Check each clue and try again.'
                : 'Only one order satisfies all clues.',
              style: const TextStyle(color: ink, fontSize: 12,
                fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${session.swaps} swaps',
                style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 12))),
              FilledButton.icon(
                key: const ValueKey('order-check'),
                onPressed: session.complete
                    ? () => setState(() { revision++; _restart(); })
                    : _check,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7A78C4),
                  foregroundColor: Colors.white),
                icon: Icon(session.complete
                    ? Icons.refresh_rounded : Icons.check_rounded),
                label: Text(session.complete ? 'PLAY AGAIN' : 'CHECK')),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() { revision++; _restart(); }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
          ]),
        ),
      ))),
    );
  }
}
