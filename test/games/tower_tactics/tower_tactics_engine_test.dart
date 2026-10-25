import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/tower_tactics/tower_tactics_engine.dart';

void main() {
  group('TowerTacticsSession', () {
    test('seeded sessions generate the same solvable boards', () {
      final first = TowerTacticsSession(seed: 42);
      final second = TowerTacticsSession(seed: 42);

      expect(first.board, second.board);
      expect(first.targetPeg, second.targetPeg);
      expect(first.diskCount, second.diskCount);
      expect(first.board[first.targetPeg].length, lessThan(first.diskCount));
      for (var round = 0; round < first.roundCount; round++) {
        final solution = _shortestSolution(first);
        expect(solution, isNotNull, reason: 'round ${round + 1} must be solvable');
        for (final move in solution!) {
          expect(first.move(move.$1, move.$2), isTrue);
        }
        if (round + 1 < first.roundCount) {
          expect(first.complete, isFalse);
          expect(first.round, round + 2);
        }
      }
      expect(first.complete, isTrue);
      expect(first.roundsCompleted, first.roundCount);
    });

    test('rejects illegal moves without changing the board or move count', () {
      final session = TowerTacticsSession(seed: 18);
      final before = session.board;
      final moves = session.moves;

      expect(session.move(-1, 0), isFalse);
      expect(session.move(0, 3), isFalse);
      expect(session.move(1, 1), isFalse);
      expect(TowerTacticsSession.canPlace(3, 1), isFalse,
          reason: 'a larger disk cannot cover a smaller top disk');
      expect(TowerTacticsSession.canPlace(2, 3), isTrue);
      expect(TowerTacticsSession.canPlace(2, null), isTrue);
      expect(session.board, before);
      expect(session.moves, moves);
    });

    test('board snapshot cannot mutate the live puzzle', () {
      final session = TowerTacticsSession(seed: 7);
      final snapshot = session.board;

      expect(() => snapshot.first.add(99), throwsUnsupportedError);
      expect(session.board, snapshot);
    });

    test('ignores moves after the last tower is complete', () {
      final session = TowerTacticsSession(seed: 91);
      while (!session.complete) {
        final solution = _shortestSolution(session)!;
        for (final move in solution) {
          session.move(move.$1, move.$2);
        }
      }
      final board = session.board;
      final moves = session.moves;

      expect(session.move(0, 1), isFalse);
      expect(session.board, board);
      expect(session.moves, moves);
    });
  });
}

List<(int, int)>? _shortestSolution(TowerTacticsSession session) {
  final start = session.board.map((peg) => List<int>.of(peg)).toList();
  final queue = Queue<_Node>()..add(_Node(start, []));
  final visited = <String>{_key(start)};
  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    if (node.board[session.targetPeg].length == session.diskCount) {
      return node.path;
    }
    for (var from = 0; from < TowerTacticsSession.pegCount; from++) {
      if (node.board[from].isEmpty) continue;
      for (var to = 0; to < TowerTacticsSession.pegCount; to++) {
        if (from == to) continue;
        final moving = node.board[from].last;
        if (node.board[to].isNotEmpty && node.board[to].last < moving) continue;
        final next = node.board.map((peg) => List<int>.of(peg)).toList();
        next[to].add(next[from].removeLast());
        if (visited.add(_key(next))) {
          queue.add(_Node(next, [...node.path, (from, to)]));
        }
      }
    }
  }
  return null;
}

String _key(List<List<int>> board) => board.map((peg) => peg.join()).join('|');

class _Node {
  const _Node(this.board, this.path);
  final List<List<int>> board;
  final List<(int, int)> path;
}
