import 'package:flutter/material.dart';
import 'water_jugs_engine.dart';

/// Standalone capacity-measuring puzzle; global progression is app-owned.
class WaterJugsPage extends StatefulWidget {
  const WaterJugsPage({super.key, this.floor, required this.onComplete,
    required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int mistakes) onSessionEnd;
  @override
  State<WaterJugsPage> createState() => _WaterJugsPageState();
}

class _WaterJugsPageState extends State<WaterJugsPage> {
  late WaterJugsSession session;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    session = WaterJugsSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1103 + revision);
    reported = false;
  }

  void _action(JugAction action) {
    if (reported || !session.perform(action)) return;
    setState(() {});
    if (reported || !session.complete) return;
    reported = true;
    widget.onSessionEnd(session.round, session.totalMoves,
        session.invalidActions);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF374C79);
    return Scaffold(
      backgroundColor: const Color(0xFFE6F2FF),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF6FAFF),
        foregroundColor: ink,
        title: const Text('Water Jugs',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(padding: const EdgeInsets.only(right: 15),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                color: Color(0xFF667CA4), fontWeight: FontWeight.w900,
                fontSize: 12)))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFCCECFF), Color(0xFFE4E6FE),
              Color(0xFFFFEADB)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.water_drop_rounded,
                color: Color(0xFF598EC7)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Measure the exact amount',
                style: TextStyle(color: ink, fontSize: 13,
                  fontWeight: FontWeight.w900))),
              Text('${session.round} / ${session.roundCount}',
                style: const TextStyle(color: Color(0xFF6D74B0),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xF5FFFFFF),
                borderRadius: BorderRadius.circular(18)),
              child: Text(session.complete
                ? 'All three measurements complete!'
                : 'TARGET  ${session.puzzle.goal} L',
                style: const TextStyle(color: ink, fontSize: 22,
                  fontWeight: FontWeight.w900)),
            ),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              return Center(child: SizedBox(
                height: bounds.maxHeight.clamp(0.0, 250.0).toDouble(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _jug('A', session.complete ? 1 : session.puzzle.capacityA,
                      session.state.a),
                    _jug('B', session.complete ? 1 : session.puzzle.capacityB,
                      session.state.b),
                  ],
                ),
              ));
            })),
            const Text('Fill, empty or pour between the two jugs.',
              style: TextStyle(color: Color(0xFF627AA0), fontSize: 12),
              textAlign: TextAlign.center),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(child: _actionButton('FILL A', JugAction.fillA)),
              const SizedBox(width: 8),
              Expanded(child: _actionButton('FILL B', JugAction.fillB)),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: _actionButton('EMPTY A', JugAction.emptyA)),
              const SizedBox(width: 8),
              Expanded(child: _actionButton('EMPTY B', JugAction.emptyB)),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: _actionButton('A → B', JugAction.pourAtoB)),
              const SizedBox(width: 8),
              Expanded(child: _actionButton('B → A', JugAction.pourBtoA)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('${session.totalMoves} moves',
                style: const TextStyle(color: ink,
                  fontWeight: FontWeight.w900, fontSize: 13))),
              TextButton.icon(
                onPressed: session.complete || session.previous == null
                    ? null : () => setState(session.undo),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('UNDO'),
              ),
              IconButton(
                tooltip: 'Restart',
                onPressed: () => setState(() {
                  revision++;
                  _reset();
                }),
                icon: const Icon(Icons.restart_alt_rounded, color: ink)),
            ]),
            if (session.complete)
              FilledButton(
                onPressed: () => setState(() { revision++; _reset(); }),
                child: const Text('PLAY AGAIN')),
          ]),
        ),
      ))),
    );
  }

  Widget _actionButton(String title, JugAction action) => SizedBox(
    height: 43,
    child: FilledButton(
      key: ValueKey('jug-${action.name}'),
      onPressed: session.complete ? null : () => _action(action),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF777BC4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14))),
      child: Text(title, style: const TextStyle(
        fontWeight: FontWeight.w900, fontSize: 12)),
    ),
  );

  Widget _jug(String label, int capacity, int water) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Text('$label · $water / $capacity L',
          style: const TextStyle(color: Color(0xFF374C79),
            fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 9),
        Expanded(child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 125),
          decoration: BoxDecoration(
            color: const Color(0xEFFFFFFF),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10), bottom: Radius.circular(20)),
            border: Border.all(color: const Color(0xFF84A8CF), width: 3)),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: water / capacity,
              widthFactor: 1,
              child: const DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFACECF8), Color(0xFF61B1E9)]))),
            ),
          ),
        )),
      ]),
    ),
  );
}
