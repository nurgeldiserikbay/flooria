import 'package:flutter/material.dart';

import 'balance_scale_engine.dart';

/// Standalone balance puzzle. No dependency on app routing or preferences.
class BalanceScalePage extends StatefulWidget {
  const BalanceScalePage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int attempts) onSessionEnd;

  @override
  State<BalanceScalePage> createState() => _BalanceScalePageState();
}

class _BalanceScalePageState extends State<BalanceScalePage> {
  late BalanceScaleSession game;
  int revision = 0;
  bool rewarded = false;
  bool showWrong = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = BalanceScaleSession(
      seed: widget.floor == null
          ? DateTime.now().microsecondsSinceEpoch
          : widget.floor! * 1013 + revision,
    );
    rewarded = false;
    showWrong = false;
  }

  void _select(int index) {
    if (rewarded || !game.toggle(index)) return;
    setState(() => showWrong = false);
  }

  void _submit() {
    if (rewarded || game.selected.isEmpty) return;
    final won = game.submit();
    setState(() => showWrong = !won);
    if (!game.complete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(game.round, game.attempts);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF3D517D);
    final target = game.complete ? 0 : game.target;
    final current = game.complete ? 0 : game.placedWeight;
    final difference = current - target;
    final tilt = difference.clamp(-12, 12) / 12;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF1F9FF),
        foregroundColor: text,
        title: const Text('Balance Scale',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF778BAF))),
            )),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFC8E9F9),
                    Color(0xFFF1E2FC),
                    Color(0xFFFFE8D8),
                  ],
                ),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.balance_rounded,
                      size: 22, color: Color(0xFF6F71BD)),
                  const SizedBox(width: 7),
                  const Expanded(child: Text('Match the weight',
                      style: TextStyle(fontSize: 14,
                          color: text, fontWeight: FontWeight.w900))),
                  Text('${game.round} / ${game.roundCount}',
                      style: const TextStyle(
                          color: Color(0xFF7167A6),
                          fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 10),
                Expanded(child: LayoutBuilder(builder: (context, box) {
                  final unit = box.maxWidth.clamp(0.0, 380.0).toDouble();
                  return Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: (box.maxHeight * .54).clamp(140.0, 250.0),
                        child: Stack(alignment: Alignment.center, children: [
                          Positioned(bottom: 14,
                            child: Container(width: 30, height: 86,
                              decoration: BoxDecoration(
                                color: const Color(0xFF788DB5),
                                borderRadius: BorderRadius.circular(12)))),
                          Positioned(bottom: 2,
                            child: Container(width: 120, height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF607CA5),
                                borderRadius: BorderRadius.circular(13)))),
                          Transform.rotate(
                            angle: tilt * .16,
                            child: SizedBox(width: unit, height: 145,
                              child: Stack(children: [
                                Positioned(left: 10, right: 10, top: 54,
                                  child: Container(height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7187B4),
                                      borderRadius: BorderRadius.circular(10)))),
                                Positioned(top: 51, left: unit * .12,
                                  child: _pan(target, const Color(0xFFFFD992),
                                    'TARGET')),
                                Positioned(top: 51, right: unit * .12,
                                  child: _pan(current,
                                    const Color(0xFFC0EDD8), 'YOURS')),
                              ]),
                            ),
                          ),
                          Positioned(top: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xF5FFFFFF),
                                borderRadius: BorderRadius.circular(20)),
                              child: Text(game.complete
                                ? 'Balanced!'
                                : current == target ? 'Ready to check!'
                                : 'Choose weights',
                                style: const TextStyle(color: text,
                                    fontWeight: FontWeight.w900)))),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      if (game.complete)
                        const Text('All three scales balanced!',
                          style: TextStyle(color: text,
                              fontSize: 19, fontWeight: FontWeight.w900))
                      else
                        const Text('Tap weights to add or remove them',
                          style: TextStyle(color: text, fontSize: 12)),
                    ],
                  ));
                })),
                const SizedBox(height: 8),
                if (!game.complete)
                  SizedBox(height: 83, child: Row(children: [
                    for (var i = 0; i < game.weights.length; i++)
                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Semantics(
                          button: true,
                          selected: game.selected.contains(i),
                          label: 'Weight ${game.weights[i]}',
                          child: InkWell(
                            key: ValueKey('balance-weight-$i'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _select(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              decoration: BoxDecoration(
                                color: game.selected.contains(i)
                                  ? const Color(0xFFB6EDCA)
                                  : const Color(0xFFF9FCFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: game.selected.contains(i)
                                    ? const Color(0xFF61BA94)
                                    : const Color(0xFFAFC4E9), width: 2)),
                              child: Center(child: Text('${game.weights[i]}',
                                style: const TextStyle(color: text,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900))),
                            ),
                          ),
                        ),
                      )),
                  ])),
                const SizedBox(height: 9),
                if (showWrong)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('Not balanced yet. Adjust the weights.',
                      style: TextStyle(
                        color: Color(0xFFAA5C62), fontSize: 12)),
                  ),
                Row(children: [
                  Expanded(child: Text('${game.attempts} checks',
                    style: const TextStyle(color: Color(0xFF64779A),
                      fontWeight: FontWeight.w800, fontSize: 12))),
                  FilledButton(
                    onPressed: game.complete
                        ? () => setState(() { revision++; _reset(); })
                        : game.selected.isEmpty ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD17D),
                      foregroundColor: const Color(0xFF374D7B)),
                    child: Text(game.complete ? 'PLAY AGAIN' : 'CHECK'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Restart',
                    onPressed: () => setState(() { revision++; _reset(); }),
                    icon: const Icon(Icons.refresh_rounded, color: text)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pan(int weight, Color color, String label) =>
    Column(children: [
      Container(
        width: 4, height: 44, color: const Color(0xFF8799BC)),
      Container(
        width: 94, height: 48,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(18)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$weight', style: const TextStyle(
            color: Color(0xFF3D517D), fontWeight: FontWeight.w900,
            fontSize: 22)),
          Text(label, style: const TextStyle(
            color: Color(0xFF5A6D93), fontWeight: FontWeight.w800,
            fontSize: 9)),
        ]),
      ),
    ]);
}
