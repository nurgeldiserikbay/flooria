import 'package:flutter/material.dart';

import 'crate_courier_engine.dart';

class CrateCourierPage extends StatefulWidget {
  const CrateCourierPage({
    super.key,
    this.floor,
    required this.onComplete,
    required this.onSessionEnd,
  });

  final int? floor;
  final VoidCallback onComplete;
  final void Function(int solvedRounds, int moves, int pushes) onSessionEnd;

  @override
  State<CrateCourierPage> createState() => _CrateCourierPageState();
}

class _CrateCourierPageState extends State<CrateCourierPage> {
  late CrateCourierSession session;
  int _revision = 0;
  bool _roundSolved = false;
  bool _reported = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final floor = (widget.floor ?? 1).clamp(1, 20).toInt();
    final seed = widget.floor == null
        ? DateTime.now().microsecondsSinceEpoch + _revision
        : widget.floor! * 15485863 + _revision;
    _revision++;
    session = CrateCourierSession(seed: seed, level: floor);
    _roundSolved = false;
    _reported = false;
    _message = null;
  }

  void _move(CourierDirection direction) {
    if (_roundSolved || session.finished) return;
    final result = session.currentBoard.move(direction);
    if (result == CourierMoveResult.blocked) {
      setState(() => _message = 'Blocked — try another route.');
      return;
    }

    setState(() {
      _message = result == CourierMoveResult.pushed
          ? 'Crate moved. Find a path to the dock.'
          : null;
      _roundSolved = result == CourierMoveResult.solved;
      if (_roundSolved) _message = 'Every crate is on its dock!';
    });
  }

  void _nextRound() {
    if (!_roundSolved) return;
    final advanced = session.advanceRound();
    if (!advanced) return;

    if (session.finished && !_reported) {
      _reported = true;
      widget.onSessionEnd(
        session.solvedCount,
        session.totalMoves,
        session.totalPushes,
      );
      if (widget.floor != null && session.passed) widget.onComplete();
    }

    setState(() {
      _roundSolved = false;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = session.finished;
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Crate Courier',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${session.totalPushes} pushes',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      finished
                          ? 'Warehouse route complete'
                          : 'Warehouse ${session.roundIndex + 1} of ${CrateCourierSession.roundCount}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE6EEE8),
                      color: _teal,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: finished
                        ? _CourierResults(
                            moves: session.totalMoves,
                            pushes: session.totalPushes,
                            passed: session.passed,
                            onRetry: () => setState(_startSession),
                          )
                        : _gameArea(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameArea() {
    final board = session.currentBoard;
    return Column(
      children: [
        const Text(
          'Push every crate onto a glowing dock. Crates cannot be pulled.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Expanded(child: _BoardView(board: board)),
        const SizedBox(height: 5),
        if (_roundSolved)
          _DeliveryCard(
            moves: board.moves,
            pushes: board.pushes,
            onContinue: _nextRound,
            finalRound: session.roundIndex == CrateCourierSession.roundCount - 1,
          )
        else
          _DirectionPad(
            moves: board.moves,
            pushes: board.pushes,
            message: _message,
            onMove: _move,
          ),
      ],
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({required this.board});

  final CrateBoard board;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / board.size;
          final side = (constraints.maxHeight < constraints.maxWidth
                  ? constraints.maxHeight
                  : constraints.maxWidth)
              .floorToDouble();
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: board.size * board.size,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: board.size,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final point = BoardPoint(index ~/ board.size, index % board.size);
                  final border = point.row == 0 ||
                      point.col == 0 ||
                      point.row == board.size - 1 ||
                      point.col == board.size - 1 ||
                      board.walls.contains(point);
                  final crateIndex = board.crates.indexOf(point);
                  final isPlayer = board.player == point;
                  final isTarget = board.targets.contains(point);
                  final tileColor = border
                      ? _wall
                      : ((point.row + point.col).isEven ? _tileA : _tileB);

                  return Container(
                    key: ValueKey('courier-cell-${point.row}-${point.col}'),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isTarget
                          ? Border.all(color: _gold, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: border
                          ? const Icon(Icons.circle, size: 7, color: _wallDot)
                          : isPlayer
                              ? const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 21,
                                  color: _purple,
                                )
                              : crateIndex >= 0
                                  ? Icon(
                                      Icons.inventory_2_rounded,
                                      size: 20,
                                      color: isTarget ? _teal : _coral,
                                    )
                                  : isTarget
                                      ? const Icon(
                                          Icons.star_rounded,
                                          size: 19,
                                          color: _gold,
                                        )
                                      : null,
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({
    required this.moves,
    required this.pushes,
    required this.message,
    required this.onMove,
  });

  final int moves;
  final int pushes;
  final String? message;
  final ValueChanged<CourierDirection> onMove;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 174,
            height: 104,
            child: Column(
              children: [
                _MoveButton(
                  direction: CourierDirection.up,
                  onMove: onMove,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MoveButton(
                      direction: CourierDirection.left,
                      onMove: onMove,
                    ),
                    Container(
                      width: 46,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _softMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: _teal,
                        size: 21,
                      ),
                    ),
                    _MoveButton(
                      direction: CourierDirection.right,
                      onMove: onMove,
                    ),
                  ],
                ),
                _MoveButton(
                  direction: CourierDirection.down,
                  onMove: onMove,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message ?? '$moves moves · $pushes pushes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: message == null ? _muted : _coral,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
        ],
      );
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.direction, required this.onMove});

  final CourierDirection direction;
  final ValueChanged<CourierDirection> onMove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (direction) {
      CourierDirection.up => Icons.keyboard_arrow_up_rounded,
      CourierDirection.right => Icons.keyboard_arrow_right_rounded,
      CourierDirection.down => Icons.keyboard_arrow_down_rounded,
      CourierDirection.left => Icons.keyboard_arrow_left_rounded,
    };
    return SizedBox(
      width: 46,
      height: 44,
      child: IconButton.filledTonal(
        key: ValueKey('courier-move-${direction.name}'),
        onPressed: () => onMove(direction),
        icon: Icon(icon, size: 28),
        style: IconButton.styleFrom(
          backgroundColor: _softLilac,
          foregroundColor: _purple,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.moves,
    required this.pushes,
    required this.onContinue,
    required this.finalRound,
  });

  final int moves;
  final int pushes;
  final VoidCallback onContinue;
  final bool finalRound;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _softMint,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _teal, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delivered in $moves moves · $pushes pushes',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              key: const ValueKey('courier-next'),
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(finalRound ? 'FINISH' : 'NEXT'),
            ),
          ],
        ),
      );
}

class _CourierResults extends StatelessWidget {
  const _CourierResults({
    required this.moves,
    required this.pushes,
    required this.passed,
    required this.onRetry,
  });

  final int moves;
  final int pushes;
  final bool passed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.local_shipping_rounded : Icons.refresh_rounded,
              color: passed ? _teal : _coral,
              size: 62,
            ),
            const SizedBox(height: 10),
            Text(
              passed ? 'All crates delivered!' : 'Route the crates again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$moves moves · $pushes pushes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFFFAFBF8);
const _ink = Color(0xFF46504B);
const _muted = Color(0xFF8B9690);
const _teal = Color(0xFF5D9E88);
const _coral = Color(0xFFC97D72);
const _purple = Color(0xFF8274AE);
const _softLilac = Color(0xFFF0ECF8);
const _softMint = Color(0xFFE5F2EA);
const _gold = Color(0xFFE0B65D);
const _wall = Color(0xFFDDE5DF);
const _wallDot = Color(0xFFAEBBB1);
const _tileA = Color(0xFFF6F8F3);
const _tileB = Color(0xFFEDF2EC);
