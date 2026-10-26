import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/crate_courier/crate_courier_engine.dart';

void main() {
  group('CrateCourierSession', () {
    test('seeded rounds repeat with distinct starts and targets', () {
      final first = CrateCourierSession(seed: 91, level: 15);
      final second = CrateCourierSession(seed: 91, level: 15);

      expect(first.rounds.length, CrateCourierSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index].board;
        final b = second.rounds[index].board;
        expect(a.playerStart, b.playerStart);
        expect(a.crates, b.crates);
        expect(a.targets, b.targets);
        expect(a.targets.length, a.crates.length);
        expect(a.crates.toSet().intersection(a.targets).length, lessThan(a.crates.length));
      }
    });

    test('every seeded board has a legal route to all its docks', () {
      for (final level in <int>[1, 7, 15]) {
        for (var seed = 0; seed < 12; seed++) {
          final session = CrateCourierSession(seed: seed, level: level);
          for (final round in session.rounds) {
            expect(_findSolution(round.board), isNotNull,
                reason: 'level $level seed $seed');
          }
        }
      }
    });

    test('blocked moves leave board and counters unchanged', () {
      final board = CrateCourierSession(seed: 17).currentBoard;
      final player = board.player;
      final crates = board.crates;
      final moves = board.moves;
      final pushes = board.pushes;

      expect(board.move(CourierDirection.down), CourierMoveResult.blocked);
      expect(board.player, player);
      expect(board.crates, crates);
      expect(board.moves, moves);
      expect(board.pushes, pushes);
    });

    test('a legal push advances the courier and counts once', () {
      final board = CrateCourierSession(seed: 23).currentBoard;
      final route = _findSolution(board)!;
      for (final direction in route) {
        board.move(direction);
        if (board.pushes > 0) break;
      }
      expect(board.pushes, 1);
      expect(board.moves, greaterThan(0));
    });

    test('rounds advance only after every crate reaches a dock', () {
      final session = CrateCourierSession(seed: 105, level: 12);
      expect(session.advanceRound(), isFalse);

      for (var index = 0; index < CrateCourierSession.roundCount; index++) {
        final route = _findSolution(session.currentBoard)!;
        for (final direction in route) {
          session.currentBoard.move(direction);
        }
        expect(session.currentBoard.solved, isTrue);
        expect(session.advanceRound(), isTrue);
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.solvedCount, CrateCourierSession.roundCount);
      expect(session.progress, 1);
      expect(session.advanceRound(), isFalse);
    });

    test('higher floors introduce more crates', () {
      final early = CrateCourierSession(seed: 4, level: 1);
      final middle = CrateCourierSession(seed: 4, level: 7);
      final late = CrateCourierSession(seed: 4, level: 15);

      expect(early.rounds.every((round) => round.board.crates.length == 1), isTrue);
      expect(middle.rounds.every((round) => round.board.crates.length == 2), isTrue);
      expect(late.rounds.every((round) => round.board.crates.length == 3), isTrue);
    });
  });
}

class _SearchState {
  const _SearchState(this.player, this.crates);
  final BoardPoint player;
  final List<BoardPoint> crates;
}

class _SearchNode {
  const _SearchNode(this.state, this.parent, this.direction);
  final _SearchState state;
  final String? parent;
  final CourierDirection? direction;
}

List<CourierDirection>? _findSolution(CrateBoard board) {
  final start = _SearchState(board.playerStart, board.crates);
  final startKey = _stateKey(start);
  final nodes = <String, _SearchNode>{
    startKey: _SearchNode(start, null, null),
  };
  final queue = <String>[startKey];
  var cursor = 0;
  String? goalKey;

  while (cursor < queue.length) {
    final key = queue[cursor++];
    final state = nodes[key]!.state;
    if (state.crates.every(board.targets.contains)) {
      goalKey = key;
      break;
    }

    for (final direction in CourierDirection.values) {
      final next = state.player + direction.offset;
      if (_isWall(next, board)) continue;
      final crates = List<BoardPoint>.of(state.crates);
      final crateIndex = crates.indexOf(next);
      if (crateIndex >= 0) {
        final beyond = next + direction.offset;
        if (_isWall(beyond, board) || crates.contains(beyond)) continue;
        crates[crateIndex] = beyond;
      }
      final candidate = _SearchState(next, crates);
      final candidateKey = _stateKey(candidate);
      if (nodes.containsKey(candidateKey)) continue;
      nodes[candidateKey] = _SearchNode(candidate, key, direction);
      queue.add(candidateKey);
    }
  }

  if (goalKey == null) return null;
  final path = <CourierDirection>[];
  var current = goalKey;
  while (nodes[current]!.parent != null) {
    final node = nodes[current]!;
    path.add(node.direction!);
    current = node.parent!;
  }
  return path.reversed.toList();
}

String _stateKey(_SearchState state) {
  final boxes = state.crates.map((point) => '${point.row},${point.col}').toList()
    ..sort();
  return '${state.player.row},${state.player.col}|${boxes.join(';')}';
}

bool _isWall(BoardPoint point, CrateBoard board) =>
    point.row <= 0 ||
    point.col <= 0 ||
    point.row >= board.size - 1 ||
    point.col >= board.size - 1 ||
    board.walls.contains(point);
