import 'package:flutter/material.dart';

import 'logic_gates_engine.dart';

class LogicGatesPage extends StatefulWidget {
  const LogicGatesPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int mistakes) onSessionEnd;

  @override
  State<LogicGatesPage> createState() => _LogicGatesPageState();
}

class _LogicGatesPageState extends State<LogicGatesPage> {
  late LogicGatesSession game;
  int revision = 0;
  bool reported = false;
  bool wrong = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = LogicGatesSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1733 + revision);
    reported = false;
    wrong = false;
  }

  void _toggle(int index) {
    if (reported || !game.toggle(index)) return;
    setState(() => wrong = false);
  }

  void _check() {
    if (reported) return;
    final success = game.check();
    setState(() => wrong = !success);
    if (reported || !game.complete) return;
    reported = true;
    widget.onSessionEnd(game.round, game.totalMoves, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _lamp(bool lit, {bool target = false}) => Container(
    width: 35,
    height: 35,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: lit
          ? const Color(0xFF7DD8AD)
          : const Color(0xFFCDD7E7),
      border: Border.all(
        color: lit
            ? const Color(0xFF4DAD88)
            : const Color(0xFF9FACCA), width: 2)),
    child: Icon(lit ? Icons.bolt_rounded : Icons.remove_rounded,
      color: lit ? const Color(0xFF246C57)
          : const Color(0xFF8899B5), size: 21),
  );

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF364D79);
    final output = game.outputs;
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FF),
      appBar: AppBar(
        title: const Text('Logic Gates',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        toolbarHeight: 48,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  color: Color(0xFF7185AA),
                  fontWeight: FontWeight.w900)))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFCFEFF9),
                Color(0xFFE5E1FB), Color(0xFFFFEBDB)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF737EBD)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Make every signal match',
                style: TextStyle(color: ink, fontWeight: FontWeight.w900,
                  fontSize: 14))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF7580AC))),
            ]),
            const SizedBox(height: 6),
            const Text('Tap switches to change the gate outputs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF627AA4))),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xF7FFFFFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBECEE9), width: 2)),
              child: Row(children: [
                for (var index = 0; index < 4; index++)
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color: game.switches[index]
                          ? const Color(0xFFA9E5D3)
                          : const Color(0xFFDEE6F8),
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        key: ValueKey('logic-switch-$index'),
                        onTap: game.complete ? null : () => _toggle(index),
                        borderRadius: BorderRadius.circular(13),
                        child: SizedBox(height: 68,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(String.fromCharCode(65 + index),
                                style: const TextStyle(color: ink,
                                  fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(game.switches[index] ? 'ON' : 'OFF',
                                style: const TextStyle(color: ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                            ]),
                        ),
                      ),
                    ),
                  )),
              ]),
            ),
            const SizedBox(height: 11),
            Expanded(child: LayoutBuilder(builder: (context, limits) {
              return Column(children: [
                for (var i = 0; i < 3; i++)
                  Expanded(child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xF7FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFC1D0EB))),
                    child: Row(children: [
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GATE ${i + 1}',
                            style: const TextStyle(color: ink,
                              fontSize: 10, fontWeight: FontWeight.w900)),
                          Text(
                            '${String.fromCharCode(65 + game.rules[i].first)} '
                            '${game.rules[i].kind.name.toUpperCase()} '
                            '${String.fromCharCode(65 + game.rules[i].second)}'
                            '${game.rules[i].invert ? ' → NOT' : ''}',
                            style: const TextStyle(color: ink,
                              fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      )),
                      Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _lamp(output[i]),
                          const Text('LIVE', style: TextStyle(fontSize: 9,
                            color: ink, fontWeight: FontWeight.w900)),
                        ]),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.compare_arrows_rounded,
                          color: Color(0xFF8D9CB9), size: 18)),
                      Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _lamp(game.target[i], target: true),
                          const Text('GOAL', style: TextStyle(fontSize: 9,
                            color: ink, fontWeight: FontWeight.w900)),
                        ]),
                    ]),
                  )),
              ]);
            })),
            Text(game.complete
                ? 'Great job! All circuits solved.'
                : wrong ? 'Not yet — compare each output to the goal.'
                : game.matched ? 'Signals match! Tap CHECK.'
                : 'Green = ON. Grey = OFF.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink,
                fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${game.totalMoves} toggles',
                style: const TextStyle(color: ink,
                  fontSize: 12, fontWeight: FontWeight.w900))),
              FilledButton.icon(
                key: const ValueKey('logic-check'),
                onPressed: game.complete
                    ? () => setState(() { revision++; _restart(); })
                    : _check,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C76C6),
                  foregroundColor: Colors.white),
                icon: Icon(game.complete
                    ? Icons.refresh_rounded : Icons.check_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'CHECK')),
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
