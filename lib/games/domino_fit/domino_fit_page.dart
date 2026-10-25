import 'package:flutter/material.dart';
import 'domino_fit_engine.dart';

class DominoFitPage extends StatefulWidget {
  const DominoFitPage({super.key, this.floor, required this.onComplete,
      required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves, int removals) onSessionEnd;

  @override
  State<DominoFitPage> createState() => _DominoFitPageState();
}

class _DominoFitPageState extends State<DominoFitPage> {
  late DominoFitSession game;
  int revision = 0;
  bool rewarded = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    game = DominoFitSession(seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1279 + revision);
    rewarded = false;
  }

  void _tap(int cell) {
    if (rewarded || !game.tap(cell)) return;
    setState(() {});
    if (!game.complete || rewarded) return;
    rewarded = true;
    widget.onSessionEnd(game.round, game.moves, game.removals);
    if (widget.floor != null) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF354E78);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FE),
      appBar: AppBar(
        title: const Text('Domino Fit',
            style: TextStyle(fontWeight: FontWeight.w900)),
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF5FAFF),
        foregroundColor: ink,
        actions: [
          if (widget.floor != null)
            Center(child: Padding(padding: const EdgeInsets.only(right: 16),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 12,
                color: Color(0xFF7287AC))))),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFCEEBFC), Color(0xFFE5DFFA),
                Color(0xFFFFEAD9)])),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.dashboard_customize_rounded,
                color: Color(0xFF797BBF)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Cover the whole board',
                style: TextStyle(color: ink, fontSize: 14,
                  fontWeight: FontWeight.w900))),
              Text('${game.round} / ${game.roundCount}',
                style: const TextStyle(color: Color(0xFF707AB0),
                  fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 9),
            const Text('Tap two neighboring squares to place one domino.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6880A4), fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(child: LayoutBuilder(builder: (context, size) {
              final width = size.biggest.shortestSide.clamp(0.0, 430.0);
              return Center(child: Container(
                width: width,
                height: width,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xEEFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC4CBE9), width: 2)),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 16,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 5,
                    mainAxisSpacing: 5),
                  itemBuilder: (context, index) {
                    final blocked = game.blocked.contains(index);
                    final partner = game.placed[index];
                    final chosen = game.anchor == index;
                    final hasDomino = partner != null;
                    final horizontal = hasDomino &&
                        partner ~/ 4 == index ~/ 4;
                    final color = blocked
                        ? const Color(0xFFBEC6D6)
                        : hasDomino
                            ? horizontal
                                ? const Color(0xFF9BDDD0)
                                : const Color(0xFFFFD49E)
                            : chosen
                                ? const Color(0xFFB4B2F1)
                                : const Color(0xFFF4F9FF);
                    return Semantics(
                      button: !blocked,
                      label: blocked ? 'Blocked square'
                        : hasDomino ? 'Remove domino'
                        : chosen ? 'Selected first square'
                        : 'Select square',
                      child: Material(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          key: ValueKey('domino-cell-$index'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: blocked ? null : () => _tap(index),
                          child: Center(child: Icon(
                            blocked
                                ? Icons.close_rounded
                                : hasDomino
                                    ? horizontal
                                        ? Icons.drag_handle_rounded
                                        : Icons.more_vert_rounded
                                    : chosen
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.add_rounded,
                            size: 27,
                            color: blocked
                                ? const Color(0xFF96A4BC)
                                : hasDomino
                                    ? const Color(0xFF527E8B)
                                    : const Color(0xFFA2B0D2))),
                        ),
                      ),
                    );
                  },
                ),
              ));
            })),
            const SizedBox(height: 8),
            Text(game.complete
                ? 'Perfect fit! Three boards completed.'
                : 'Dominoes left: ${game.remaining} • Tap a domino to remove it.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink,
                fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${game.moves} moves',
                style: const TextStyle(color: ink,
                    fontWeight: FontWeight.w900, fontSize: 13))),
              FilledButton.icon(
                onPressed: () => setState(() { revision++; _reset(); }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD78B),
                  foregroundColor: ink),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(game.complete ? 'PLAY AGAIN' : 'RESTART',
                    style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ]),
        ),
      ))),
    );
  }
}
