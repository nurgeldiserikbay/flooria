import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/merge_2048.dart';
import '../game/game_objective.dart';
import 'floor_victory.dart';
import 'sliding_2048_board.dart';
import 'fantasy_ui.dart';

class MergePage extends StatefulWidget {
  final int? floor;
  final VoidCallback onComplete;
  final void Function(int score, int tile, int moves) onSessionEnd;
  const MergePage({super.key, this.floor, required this.onComplete,
    required this.onSessionEnd});
  @override
  State<MergePage> createState() => _MergePageState();
}

class _MergePageState extends State<MergePage> {
  late Merge2048 game;
  bool finished = false;
  Offset drag = Offset.zero;
  int moveAnimationId = 0;
  List<int>? previousBoard;
  MoveDirection? previousDirection;
  bool victoryPresented = false;
  bool resultReported = false;

  void _reportResult() {
    if (resultReported) return;
    resultReported = true;
    widget.onSessionEnd(game.score, game.highest, game.moves);
  }

  @override
  void initState() {
    super.initState();
    game = Merge2048(seed: widget.floor);
  }

  void move(MoveDirection d) {
    if (finished || !game.canMove) return;
    var won = false;
    setState(() {
      final before = List<int>.from(game.cells);
      if (game.move(d)) {
        previousBoard = before;
        previousDirection = d;
        moveAnimationId++;
      }
      final goal = const ObjectiveCatalog().forGame('merge2048', floor: widget.floor);
      if (goal.isComplete(game.highest)) {
        finished = true;
        won = true;
      }
    });
    if (won) {
      _onVictory();
    } else if (!game.canMove) {
      _reportResult();
    }
  }

  Future<void> _onVictory() async {
    if (victoryPresented || !mounted) return;
    victoryPresented = true;
    _reportResult();
    if (widget.floor == null) return; // Library mode has no tower unlock.
    widget.onComplete(); // Award this floor exactly once.
    final action = await showFloorVictory(context,
      completedFloor: widget.floor!,
      achievement: 'You created the ${game.highest} tile!',
      detail: 'The next neuron is ready to explore.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(action == VictoryAction.nextFloor);
  }

  @override
  Widget build(BuildContext context) {
    final objective = const ObjectiveCatalog().forGame(
      'merge2048', floor: widget.floor);
    return Scaffold(
      backgroundColor: const Color(0xFFCDE6FA),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('2048', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFE3EFFF),
        foregroundColor: const Color(0xFF2B427D),
        actions: [
          if (widget.floor != null)
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text('LEVEL ${widget.floor}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900,
                color: Color(0xFF697AA9))))),
        ],
      ),
      body: FantasyScene(child: SafeArea(child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              _mission(objective.title, game.highest, objective.target),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('SCORE', '${game.score}'),
                  _stat('BEST TILE', '${game.highest}'),
                  _stat('MOVES', '${game.moves}'),
                ]),
              const SizedBox(height: 10),
              Expanded(child: LayoutBuilder(builder: (context, available) {
                final boardSize = available.biggest.shortestSide
                  .clamp(0.0, 430.0).toDouble();
                return Center(child: SizedBox.square(
                  dimension: boardSize,
                  child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft) {
            move(MoveDirection.left);
          } else if (key == LogicalKeyboardKey.arrowRight) {
            move(MoveDirection.right);
          } else if (key == LogicalKeyboardKey.arrowUp) {
            move(MoveDirection.up);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            move(MoveDirection.down);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Direction-specific recognizers win against the parent ListView's
          // vertical scroll recognizer when a gesture begins on the board.
          onHorizontalDragStart: (_) => drag = Offset.zero,
          onHorizontalDragUpdate: (details) => drag += details.delta,
          onHorizontalDragEnd: (_) {
            if (drag.dx.abs() >= 16) {
              move(drag.dx > 0 ? MoveDirection.right : MoveDirection.left);
            }
            drag = Offset.zero;
          },
          onVerticalDragStart: (_) => drag = Offset.zero,
          onVerticalDragUpdate: (details) => drag += details.delta,
          onVerticalDragEnd: (_) {
            if (drag.dy.abs() >= 16) {
              move(drag.dy > 0 ? MoveDirection.down : MoveDirection.up);
            }
            drag = Offset.zero;
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: Sliding2048Board(
              cells: game.cells,
              previous: previousBoard,
              direction: previousDirection,
              revision: moveAnimationId,
            ),
          ),
        ),
      ),
                ));
              })),
              if (finished && widget.floor == null)
                _notice('Great! You reached the goal.'),
              if (!game.canMove && !finished)
                _notice('No moves left — start again!'),
              const SizedBox(height: 9),
              SizedBox(width: double.infinity, height: 49,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCF72),
                    foregroundColor: const Color(0xFF25366D)),
                  onPressed: () => setState(() {
                    game = Merge2048(
                      seed: DateTime.now().millisecondsSinceEpoch);
                    finished = false;
                    resultReported = false;
                    victoryPresented = false;
                    previousBoard = null;
                    previousDirection = null;
                    moveAnimationId++;
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('RESTART', style: TextStyle(
                    fontWeight: FontWeight.w900))),
              ),
            ]),
          ),
        ),
      ))),
    );
  }

  Widget _mission(String name, int current, int target) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xEAFFFFFF),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFA6C2EC))),
    child: Row(children: [
      const Icon(Icons.flag_rounded, size: 19, color: Color(0xFF6E62C9)),
      const SizedBox(width: 7),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
          color: Color(0xFF304978)))),
      Text('${current.clamp(0, target)} / $target',
        style: const TextStyle(color: Color(0xFF6455C9),
          fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );

  Widget _stat(String label, String value) => Column(children: [
    Text(label, style: const TextStyle(color: Color(0xFF5F739D),
      fontSize: 10, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Color(0xFF2D4378),
      fontSize: 20, fontWeight: FontWeight.w900)),
  ]);
  Widget _notice(String text) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF2D6191), borderRadius: BorderRadius.circular(16)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)));
}
