import 'package:flutter/material.dart';

import 'disk_towers_engine.dart';

/// Standalone spatial planning puzzle; result persistence belongs to the app.
class DiskTowersPage extends StatefulWidget {
  const DiskTowersPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int invalidMoves) onSessionEnd;

  @override
  State<DiskTowersPage> createState() => _DiskTowersPageState();
}

class _DiskTowersPageState extends State<DiskTowersPage> {
  late DiskTowersSession game;
  int revision = 0;
  bool reported = false;
  bool showError = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final floor = widget.floor;
    game = DiskTowersSession(seed: floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : floor * 1297 + revision);
    reported = false;
    showError = false;
  }

  void _tap(int peg) {
    if (reported) return;
    final moved = game.tapPeg(peg);
    setState(() => showError = !moved);
    if (!game.complete || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.totalMoves, game.invalidMoves);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF374D7B);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Disk Towers',
            style: TextStyle(fontWeight: FontWeight.w900)),
        foregroundColor: ink,
        backgroundColor: const Color(0xFFF5FAFF),
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7483A7))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFFCCEAFB),
              Color(0xFFE5E3FA),
              Color(0xFFFFEDDE),
            ])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.layers_rounded,
                color: Color(0xFF7488C0), size: 23),
              const SizedBox(width: 8),
              const Expanded(child: Text('Build the goal tower',
                style: TextStyle(color: ink, fontSize: 14,
                  fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF717AA8),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 9),
            Text(game.complete
                ? 'All towers completed!'
                : 'Move every disk onto tower ${game.goalPeg + 1}.',
              style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w800, color: ink),
              textAlign: TextAlign.center),
            const SizedBox(height: 5),
            const Text('Choose a tower, then tap where its top disk goes.',
              style: TextStyle(fontSize: 11,
                color: Color(0xFF6B80A6)),
              textAlign: TextAlign.center),
            const SizedBox(height: 9),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              return Center(child: SizedBox(
                height: bounds.maxHeight.clamp(0.0, 305.0).toDouble(),
                child: Row(children: [
                  for (var peg = 0; peg < 3; peg++)
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _tower(peg),
                    )),
                ]),
              ));
            })),
            const SizedBox(height: 10),
            Text(game.complete
                ? 'Excellent planning!'
                : showError
                    ? 'That move is not allowed.'
                    : game.selectedPeg == null
                        ? 'Select a tower to pick up its top disk.'
                        : 'Now choose a destination tower.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: showError
                    ? const Color(0xFFB76C78)
                    : const Color(0xFF6376A1))),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${game.totalMoves} moves',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: ink))),
              FilledButton.icon(
                onPressed: () => setState(() {
                  revision++;
                  _newGame();
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7776C9),
                  foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'RESTART',
                  style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ]),
        ),
      ))),
    );
  }

  Widget _tower(int peg) {
    const ink = Color(0xFF374D7B);
    final chosen = game.selectedPeg == peg;
    final isGoal = !game.complete && game.goalPeg == peg;
    const colors = [
      Color(0xFFFFC38C),
      Color(0xFF9CDDD5),
      Color(0xFFB9B1EB),
      Color(0xFFF8D47D),
    ];
    return Material(
      color: chosen
          ? const Color(0xFFDBD9FF)
          : isGoal
              ? const Color(0xFFE4F5E9)
              : const Color(0xDFFFFFFF),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        key: ValueKey('disk-peg-$peg'),
        onTap: game.complete ? null : () => _tap(peg),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 10, 3, 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: chosen
                  ? const Color(0xFF8880D0)
                  : const Color(0xFFB5C7E5), width: 2),
            borderRadius: BorderRadius.circular(17)),
          child: Column(children: [
            Text(isGoal ? '★ GOAL' : 'TOWER ${peg + 1}',
              style: const TextStyle(color: ink,
                fontWeight: FontWeight.w900, fontSize: 10)),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              return Stack(alignment: Alignment.bottomCenter, children: [
                Positioned(
                  bottom: 5,
                  top: 10,
                  child: Container(width: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2C0D7),
                      borderRadius: BorderRadius.circular(6)))),
                for (var i = 0; i < game.pegs[peg].length; i++)
                  Positioned(
                    bottom: 8 + i * 32,
                    child: Container(
                      height: 29,
                      width: (constraints.maxWidth - 11) *
                          (.37 + .135 * game.pegs[peg][i]),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors[(game.pegs[peg][i] - 1) % colors.length],
                        border: Border.all(color: const Color(0xFF7890B3)),
                        borderRadius: BorderRadius.circular(11)),
                      child: Text('${game.pegs[peg][i]}',
                        style: const TextStyle(color: ink,
                          fontWeight: FontWeight.w900, fontSize: 13))),
                  ),
              ]);
            })),
            Container(height: 7, width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF8AA4C0),
                borderRadius: BorderRadius.circular(6))),
          ]),
        ),
      ),
    );
  }
}
