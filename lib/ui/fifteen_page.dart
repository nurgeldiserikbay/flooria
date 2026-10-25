import 'package:flutter/material.dart';
import '../game/fifteen.dart';
import 'floor_victory.dart';

/// Sliding Fifteen: own engine, screen and results; no shared mutable state.
class FifteenPage extends StatefulWidget {
  const FifteenPage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int moves) onSessionEnd;

  @override
  State<FifteenPage> createState() => _FifteenPageState();
}

class _FifteenPageState extends State<FifteenPage> {
  late FifteenSession game;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  void _newPuzzle() {
    final seed = widget.floor == null
      ? DateTime.now().microsecondsSinceEpoch
      : widget.floor! * 1931 + revision;
    game = FifteenSession(seed: seed,
      scrambleSteps: 12 + ((widget.floor ?? 1) ~/ 12).clamp(0, 5) * 5);
    reported = false;
  }

  Future<void> _tap(int index) async {
    if (reported || !game.move(index)) return;
    setState(() {});
    if (!game.isSolved) return;
    reported = true;
    widget.onSessionEnd(game.moves);
    if (widget.floor == null) return;
    widget.onComplete();
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'All fifteen tiles in order!',
      detail: 'A new neuron has opened.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE6EBFC),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Sliding Fifteen',
        style: TextStyle(fontWeight: FontWeight.w900)),
      foregroundColor: const Color(0xFF344F87),
      backgroundColor: const Color(0xFFF2F6FF),
      actions: [
        if (widget.floor != null)
          Center(child: Padding(padding: const EdgeInsets.only(right: 16),
            child: Text('LEVEL ${widget.floor}', style: const TextStyle(
              color: Color(0xFF6C83B2), fontSize: 12,
              fontWeight: FontWeight.w900)))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 16),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFC1DFFA), Color(0xFFE9DEFD), Color(0xFFFFEBD9)])),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.grid_view_rounded,
              color: Color(0xFF7166C2), size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Arrange tiles from 1 to 15',
              style: TextStyle(color: Color(0xFF354A82),
                fontSize: 14, fontWeight: FontWeight.w900))),
            Text('${game.moves} moves', style: const TextStyle(
              color: Color(0xFF655DAF), fontWeight: FontWeight.w900,
              fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final size = bounds.biggest.shortestSide.clamp(0.0, 430.0).toDouble();
            return Center(child: Container(
              width: size, height: size,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFB4C7EB),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: const Color(0xF5FFFFFF), width: 2)),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
                itemCount: 16,
                itemBuilder: (context, index) {
                  final number = game.tiles[index];
                  final movable = game.movableIndices.contains(index);
                  return Semantics(
                    button: number != 0,
                    label: number == 0 ? 'Empty space' : 'Tile $number',
                    child: number == 0
                      ? const SizedBox.expand()
                      : Material(
                        color: movable
                          ? const Color(0xFFFFF0CB)
                          : const Color(0xFFFDFEFF),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: reported ? null : () => _tap(index),
                          child: Center(child: Text('$number',
                            style: TextStyle(
                              fontSize: size < 275 ? 19 : 25,
                              color: movable
                                ? const Color(0xFFAA724F)
                                : const Color(0xFF45619B),
                              fontWeight: FontWeight.w900))),
                        ),
                      ),
                  );
                },
              ),
            ));
          })),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(game.isSolved
              ? 'Puzzle completed!'
              : 'Tap a tile next to the empty space',
              style: const TextStyle(color: Color(0xFF6079A4),
                fontSize: 12, fontWeight: FontWeight.w800))),
            FilledButton.icon(
              onPressed: () => setState(() {
                revision++;
                _newPuzzle();
              }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD583),
                foregroundColor: const Color(0xFF374779)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RESTART')),
          ]),
        ]),
      ),
    ))),
  );
}
