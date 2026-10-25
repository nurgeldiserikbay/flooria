import 'package:flutter/material.dart';

import 'tilt_trail_engine.dart';

/// Roll a marble to the star by tilting the board in four directions.
class TiltTrailPage extends StatefulWidget {
  const TiltTrailPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int rounds, int moves) onSessionEnd;

  @override
  State<TiltTrailPage> createState() => _TiltTrailPageState();
}

class _TiltTrailPageState extends State<TiltTrailPage> {
  late TiltTrailSession session;
  int revision = 0;
  bool reported = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + revision * 3253
        : widget.floor! * 3253 + revision;
    session = TiltTrailSession(seed: seed);
    reported = false;
  }

  void _tilt(TiltDirection direction) {
    if (!session.tilt(direction)) return;
    setState(() {});
  }

  void _nextRound() {
    if (!session.advance()) return;
    setState(() {});
    if (!session.complete || reported) return;

    reported = true;
    widget.onSessionEnd(TiltTrailSession.totalRounds, session.moves);
    if (widget.floor != null) widget.onComplete();
  }

  Widget _directionButton(TiltDirection? direction) {
    if (direction == null) return const SizedBox.square(dimension: 48);
    final icon = switch (direction) {
      TiltDirection.up => Icons.keyboard_arrow_up_rounded,
      TiltDirection.right => Icons.keyboard_arrow_right_rounded,
      TiltDirection.down => Icons.keyboard_arrow_down_rounded,
      TiltDirection.left => Icons.keyboard_arrow_left_rounded,
    };
    return Semantics(
      button: !session.complete && !session.roundComplete,
      label: 'Tilt ${direction.name}',
      child: SizedBox.square(
        dimension: 48,
        child: Material(
          color: const Color(0xFFFFD98A),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            key: ValueKey<String>('tilt-${direction.name}'),
            borderRadius: BorderRadius.circular(15),
            onTap: session.complete || session.roundComplete
                ? null
                : () => _tilt(direction),
            child: Icon(
              icon,
              color: const Color(0xFF5B6D71),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = session.puzzle;
    final finished = session.complete;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F4),
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Tilt Trail',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF4FBFA),
        foregroundColor: const Color(0xFF3E6A68),
        actions: [
          if (widget.floor != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Text(
                  'LEVEL ${widget.floor}',
                  style: const TextStyle(
                    color: Color(0xFF789B95),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD9F1EB),
                    Color(0xFFF3F8FF),
                    Color(0xFFFFF1D7),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_basketball_rounded,
                        color: Color(0xFF6AA9D1),
                        size: 23,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          finished
                              ? 'All trails complete!'
                              : session.roundComplete
                                  ? 'Star reached!'
                                  : 'Slide until a wall or the edge',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF426C6A),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${finished ? TiltTrailSession.totalRounds : session.round + 1} / ${TiltTrailSession.totalRounds}',
                        style: const TextStyle(
                          color: Color(0xFF688C88),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final size = bounds.biggest.shortestSide
                            .clamp(0.0, 430.0)
                            .toDouble();
                        return Center(
                          child: SizedBox.square(
                            dimension: size,
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: TiltPuzzle.size,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: TiltPuzzle.size * TiltPuzzle.size,
                              itemBuilder: (context, index) {
                                final cell = TiltCell(
                                  index ~/ TiltPuzzle.size,
                                  index % TiltPuzzle.size,
                                );
                                final isWall = puzzle.walls.contains(cell);
                                final isMarble = puzzle.position == cell;
                                final isGoal = puzzle.goal == cell;
                                return Semantics(
                                  label: isWall
                                      ? 'Wall'
                                      : isMarble && isGoal
                                          ? 'Marble on the star'
                                          : isMarble
                                              ? 'Marble'
                                              : isGoal
                                                  ? 'Goal star'
                                                  : 'Open space',
                                  child: AnimatedContainer(
                                    key: ValueKey<String>(
                                      'tilt-cell-${cell.row}-${cell.column}',
                                    ),
                                    duration: const Duration(milliseconds: 160),
                                    decoration: BoxDecoration(
                                      color: isWall
                                          ? const Color(0xFFB9D7D0)
                                          : isGoal && isMarble
                                              ? const Color(0xFFFFE18A)
                                              : isGoal
                                                  ? const Color(0xFFFFF0BD)
                                                  : const Color(0xFFFAFCFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isWall
                                            ? const Color(0xFFA5C9C0)
                                            : const Color(0xFFD9E8E8),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: isWall
                                          ? const Icon(
                                              Icons.stop_rounded,
                                              color: Color(0xFF8FB9B0),
                                              size: 20,
                                            )
                                          : isMarble && isGoal
                                              ? const Icon(
                                                  Icons.stars_rounded,
                                                  color: Color(0xFFE8A83F),
                                                  size: 30,
                                                )
                                              : isMarble
                                                  ? const Icon(
                                                      Icons.circle_rounded,
                                                      color: Color(0xFF72BCE3),
                                                      size: 29,
                                                    )
                                                  : isGoal
                                                      ? const Icon(
                                                          Icons.star_rounded,
                                                          color: Color(0xFFE8B54F),
                                                          size: 27,
                                                        )
                                                      : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${session.moves} tilts',
                            style: const TextStyle(
                              color: Color(0xFF789B95),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (session.roundComplete && !finished)
                          FilledButton.icon(
                            onPressed: _nextRound,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFBDE9D6),
                              foregroundColor: const Color(0xFF3E6A68),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('NEXT TRAIL'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => setState(() {
                              revision++;
                              _restart();
                            }),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD98A),
                              foregroundColor: const Color(0xFF5B6D71),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(finished ? 'PLAY AGAIN' : 'RESTART'),
                          ),
                      ],
                    ),
                  ),
                  if (finished)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'A clear path, one tilt at a time.',
                        style: TextStyle(
                          color: Color(0xFF527C70),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _directionButton(null),
                          _directionButton(TiltDirection.up),
                          _directionButton(null),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _directionButton(TiltDirection.left),
                          _directionButton(null),
                          _directionButton(TiltDirection.right),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _directionButton(null),
                          _directionButton(TiltDirection.down),
                          _directionButton(null),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
