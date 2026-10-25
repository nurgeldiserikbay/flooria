import 'package:flutter/material.dart';
import '../game/maze_route.dart';
import 'floor_victory.dart';

class MazeRoutePage extends StatefulWidget {
  const MazeRoutePage({super.key, this.floor,
    required this.onComplete, required this.onSessionEnd});
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int moves, int shortest) onSessionEnd;

  @override
  State<MazeRoutePage> createState() => _MazeRoutePageState();
}

class _MazeRoutePageState extends State<MazeRoutePage> {
  late MazeRouteSession game;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    game = MazeRouteSession(
      seed: widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch
        : widget.floor! * 1777 + revision,
      size: widget.floor != null && widget.floor! >= 40 ? 7 : 6);
    reported = false;
  }

  Future<void> _move(int direction) async {
    if (reported) return;
    if (!game.step(direction)) return;
    setState(() {});
    if (!game.finished) return;
    reported = true;
    widget.onSessionEnd(game.moves, game.solution().length);
    if (widget.floor == null) return;
    widget.onComplete();
    final result = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'You found the exit in ${game.moves} steps!',
      detail: 'A new neuron is ready to explore.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(result == VictoryAction.nextFloor);
  }

  Widget _direction(IconData icon, int dir) => SizedBox(
    height: 48, width: 72,
    child: FilledButton(
      key: ValueKey('maze-direction-$dir'),
      onPressed: reported ? null : () => _move(dir),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFE9F9FF),
        foregroundColor: const Color(0xFF42739A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Icon(icon, size: 26),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE6F6F6),
    appBar: AppBar(
      toolbarHeight: 48,
      title: const Text('Maze Route', style: TextStyle(fontWeight: FontWeight.w900)),
      backgroundColor: const Color(0xFFEDF9FC),
      foregroundColor: const Color(0xFF376A8B),
      actions: [
        if (widget.floor != null) Center(child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text('LEVEL ${widget.floor}',
            style: const TextStyle(color: Color(0xFF618BAC),
              fontSize: 12, fontWeight: FontWeight.w900)))),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFBBECF5), Color(0xFFE3F1FA), Color(0xFFFDE9DD)])),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.route_rounded, size: 21,
              color: Color(0xFF4588A1)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Reach the golden star',
              style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF376987), fontSize: 14))),
            Text('${game.moves} steps', style: const TextStyle(
              color: Color(0xFF537F9D), fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: LayoutBuilder(builder: (context, bounds) {
            final size = bounds.biggest.shortestSide.clamp(0.0, 430.0).toDouble();
            return Center(child: Container(
              width: size, height: size,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xDFFFFFFF),
                borderRadius: BorderRadius.circular(21)),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: game.size, childAspectRatio: 1),
                itemCount: game.passages.length,
                itemBuilder: (context, i) {
                  return Container(
                    decoration: BoxDecoration(
                      color: i == game.position
                        ? const Color(0xFFB6F1DA)
                        : i == game.exit
                          ? const Color(0xFFFFF0AF)
                          : const Color(0xFFE9F5FD),
                      border: Border(
                        top: BorderSide(color: game.canMove(i, 0)
                          ? Colors.transparent : const Color(0xFF638BAF), width: 3),
                        right: BorderSide(color: game.canMove(i, 1)
                          ? Colors.transparent : const Color(0xFF638BAF), width: 3),
                        bottom: BorderSide(color: game.canMove(i, 2)
                          ? Colors.transparent : const Color(0xFF638BAF), width: 3),
                        left: BorderSide(color: game.canMove(i, 3)
                          ? Colors.transparent : const Color(0xFF638BAF), width: 3),
                      ),
                    ),
                    child: Center(child: i == game.position
                      ? const Icon(Icons.navigation_rounded,
                          color: Color(0xFF239C85), size: 25)
                      : i == game.exit
                        ? const Icon(Icons.star_rounded,
                            color: Color(0xFFE4A542), size: 26)
                        : null),
                  );
                },
              ),
            ));
          })),
          const SizedBox(height: 6),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _direction(Icons.keyboard_arrow_up_rounded, 0),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _direction(Icons.keyboard_arrow_left_rounded, 3),
              const SizedBox(width: 56),
              _direction(Icons.keyboard_arrow_right_rounded, 1),
            ]),
            const SizedBox(height: 5),
            _direction(Icons.keyboard_arrow_down_rounded, 2),
          ]),
          const SizedBox(height: 8),
          SizedBox(height: 43, width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() { revision++; _restart(); }),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD68B),
                foregroundColor: const Color(0xFF43617E)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('NEW MAZE')),
          ),
        ]),
      ),
    ))),
  );
}
