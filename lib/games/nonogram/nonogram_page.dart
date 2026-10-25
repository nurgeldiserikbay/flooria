import 'package:flutter/material.dart';
import 'nonogram_engine.dart';

/// Standalone picture-logic puzzle. No dependency on global app state.
class NonogramPage extends StatefulWidget {
  const NonogramPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int checks, int mistakes) onSessionEnd;

  @override
  State<NonogramPage> createState() => _NonogramPageState();
}

class _NonogramPageState extends State<NonogramPage> {
  late NonogramSession game;
  int revision = 0;
  bool reported = false;
  bool checkedWrong = false;

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  void _newSession() {
    game = NonogramSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 2213 + revision);
    reported = false;
    checkedWrong = false;
  }

  void _toggle(int index) {
    if (reported || !game.toggle(index)) return;
    setState(() => checkedWrong = false);
  }

  void _check() {
    if (reported || game.filledCount == 0) return;
    final completed = game.check();
    setState(() => checkedWrong = !completed);
    if (!game.finished || reported) return;
    reported = true;
    widget.onSessionEnd(game.round, game.checks, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _hintBox(String label, {bool vertical = false, double size = 49}) =>
      Container(
        width: vertical ? size : 59,
        height: vertical ? 64 : size,
        alignment: Alignment.center,
        child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13, height: 1.05,
            color: Color(0xFF4A618B),
            fontWeight: FontWeight.w900)),
      );

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF374F7C);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Pixel Clues',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(color: Color(0xFF738AB5),
                  fontSize: 12, fontWeight: FontWeight.w900)))),
        ],
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 490),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFCEF0FA), Color(0xFFE5E3FC),
                  Color(0xFFFFE9DC)])),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.grid_on_rounded, color: Color(0xFF688EBF)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Reveal the hidden picture',
                  style: TextStyle(color: ink,
                    fontSize: 14, fontWeight: FontWeight.w900))),
                Text('${game.round} / ${game.roundCount}',
                  style: const TextStyle(
                    color: Color(0xFF6479A5),
                    fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 8),
              const Text('Numbers describe consecutive colored squares.',
                style: TextStyle(color: Color(0xFF667A9F), fontSize: 12),
                textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                // Keep the whole clue board inside the playable viewport.
                final available = constraints.biggest.shortestSide;
                final cell = ((available - 64) / 5).clamp(22.0, 67.0).toDouble();
                final fieldSize = cell * 5;
                return Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 59),
                      for (var x = 0; x < 5; x++)
                        _hintBox(game.columnClues[x].join('\n'),
                          vertical: true, size: cell),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Column(children: [
                        for (var y = 0; y < 5; y++)
                          _hintBox(game.rowClues[y].join(' '), size: cell),
                      ]),
                      SizedBox(width: fieldSize, height: fieldSize,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: 25,
                          gridDelegate: const
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5),
                          itemBuilder: (context, index) {
                            final state = game.cells[index];
                            return Material(
                              color: state == 1
                                ? const Color(0xFF83B7E9)
                                : state == 2
                                  ? const Color(0xFFF3E7EF)
                                  : const Color(0xFFF8FCFF),
                              child: InkWell(
                                key: ValueKey('nonogram-cell-$index'),
                                onTap: reported ? null : () => _toggle(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFADC2E4),
                                      width: .8)),
                                  child: Center(child: state == 2
                                    ? const Icon(Icons.close_rounded,
                                        color: Color(0xFFB48FAD), size: 22)
                                    : state == 1
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 21)
                                      : null),
                                ),
                              ),
                            );
                          },
                        )),
                    ]),
                  ],
                ));
              })),
              const SizedBox(height: 5),
              Text(game.finished
                  ? 'All three pictures completed!'
                  : checkedWrong
                    ? 'Not quite — use the row and column clues.'
                    : 'Tap: fill → cross out → clear',
                style: TextStyle(color: checkedWrong
                    ? const Color(0xFFB26E78)
                    : const Color(0xFF566F9B),
                  fontSize: 12, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
              const SizedBox(height: 9),
              Row(children: [
                Expanded(child: Text('${game.checks} checks',
                  style: const TextStyle(color: ink,
                    fontSize: 12, fontWeight: FontWeight.w900))),
                FilledButton.icon(
                  onPressed: game.finished
                    ? () => setState(() { revision++; _newSession(); })
                    : game.filledCount == 0 ? null : _check,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8173C3),
                    foregroundColor: Colors.white),
                  icon: Icon(game.finished
                    ? Icons.refresh_rounded : Icons.check_rounded),
                  label: Text(game.finished ? 'PLAY AGAIN' : 'CHECK'),
                ),
                IconButton(
                  tooltip: 'Restart puzzle',
                  onPressed: () => setState(() { revision++; _newSession(); }),
                  icon: const Icon(Icons.restart_alt_rounded,
                    color: ink)),
              ]),
            ]),
          ),
        )),
      ),
    );
  }
}
