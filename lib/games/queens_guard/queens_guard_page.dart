import 'package:flutter/material.dart';
import 'queens_guard_engine.dart';

/// Standalone 5x5 constraint puzzle. Shell owns stats and floor advancement.
class QueensGuardPage extends StatefulWidget {
  const QueensGuardPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int checks, int mistakes) onSessionEnd;

  @override
  State<QueensGuardPage> createState() => _QueensGuardPageState();
}

class _QueensGuardPageState extends State<QueensGuardPage> {
  late QueensGuardSession game;
  int revision = 0;
  bool rewarded = false;
  bool wrong = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = QueensGuardSession(seed: widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 1439 + revision);
    rewarded = false;
    wrong = false;
  }

  void _toggle(int index) {
    if (rewarded || !game.toggle(index)) return;
    setState(() => wrong = false);
  }

  void _check() {
    if (rewarded || game.queens.length != QueensGuardSession.size) return;
    final success = game.check();
    setState(() => wrong = !success);
    if (!game.complete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(game.round, game.checks, game.mistakes);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF354F79);
    final conflicts = game.conflicts;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Queens Guard',
          style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF7FBFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('LEVEL ${widget.floor}',
                style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7388AA))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFFCCEBFA), Color(0xFFE6E3FB), Color(0xFFFFE9DA),
            ])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFF7A76B9)),
              const SizedBox(width: 7),
              const Expanded(child: Text('Protect every queen',
                style: TextStyle(color: ink, fontSize: 14,
                  fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF747CAB),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 7),
            const Text('Place 5 queens. None may share a row, column or diagonal.',
              style: TextStyle(color: Color(0xFF687FA1), fontSize: 12),
              textAlign: TextAlign.center),
            const SizedBox(height: 9),
            Expanded(child: LayoutBuilder(builder: (context, bounds) {
              final side = bounds.biggest.shortestSide.clamp(0.0, 420.0);
              return Center(child: Container(
                height: side, width: side,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  border: Border.all(color: const Color(0xFFBDCAEA), width: 2),
                  borderRadius: BorderRadius.circular(22)),
                child: GridView.builder(
                  itemCount: QueensGuardSession.size * QueensGuardSession.size,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: QueensGuardSession.size,
                    mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemBuilder: (context, cell) {
                    final queen = game.queens.contains(cell);
                    final blocked = game.blocked.contains(cell);
                    final fixed = cell == game.fixedQueen;
                    final conflict = conflicts.contains(cell);
                    return Semantics(
                      button: !fixed && !blocked,
                      label: fixed ? 'Fixed queen' : blocked ? 'Blocked'
                        : queen ? 'Remove queen' : 'Place queen',
                      child: Material(
                        color: blocked ? const Color(0xFFBFC8D9)
                          : conflict ? const Color(0xFFFFC3C1)
                          : queen ? const Color(0xFFD8CCF7)
                          : (cell ~/ 5 + cell % 5).isEven
                            ? const Color(0xFFF4F9FF)
                            : const Color(0xFFE3EEFA),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: ValueKey('queens-cell-$cell'),
                          onTap: blocked || fixed ? null : () => _toggle(cell),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(child: Icon(
                            queen ? Icons.workspace_premium_rounded
                              : blocked ? Icons.close_rounded
                              : Icons.add_rounded,
                            size: queen ? 28 : 19,
                            color: fixed ? const Color(0xFFAB76A7)
                              : conflict ? const Color(0xFFB24D64)
                              : queen ? const Color(0xFF7B6DCA)
                              : blocked ? const Color(0xFF93A3B9)
                              : const Color(0xFFA5B9D5))),
                        ),
                      ),
                    );
                  },
                ),
              ));
            })),
            const SizedBox(height: 9),
            Text(game.complete ? 'All three boards solved!'
                : conflicts.isNotEmpty ? 'Red queens can attack each other.'
                : wrong ? 'Not yet — check the queens again.'
                : 'The purple queen is fixed. Grey cells are blocked.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink, fontSize: 12,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: Text('${game.queens.length}/5 queens',
                style: const TextStyle(color: ink, fontSize: 13,
                  fontWeight: FontWeight.w900))),
              FilledButton.icon(
                key: const ValueKey('queens-check-button'),
                onPressed: game.complete
                  ? () => setState(() { revision++; _restart(); })
                  : game.queens.length == QueensGuardSession.size ? _check : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7B78C6),
                  foregroundColor: Colors.white),
                icon: Icon(game.complete ? Icons.refresh_rounded
                  : Icons.check_rounded),
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
