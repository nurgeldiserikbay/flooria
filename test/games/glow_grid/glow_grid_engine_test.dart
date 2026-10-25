import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/glow_grid/glow_grid_engine.dart';

void main() {
  group('GlowGridSession', () {
    test('seeded boards are reproducible and visibly solvable', () {
      final first = GlowGridSession(seed: 8271);
      final second = GlowGridSession(seed: 8271);

      expect(second.boards.length, GlowGridSession.boardCount);
      for (var round = 0; round < first.boards.length; round++) {
        final a = first.boards[round];
        final b = second.boards[round];
        expect(a.size, b.size);
        expect(a.litCells, b.litCells);
        expect(a.scramble, b.scramble);
        expect(a.litCells, isNotEmpty);

        final solved = <int>{};
        for (final index in a.scramble) {
          _toggle(solved, a.size, index);
        }
        expect(solved, a.litCells);
      }
    });

    test('difficulty grows from 3 to 4 to 5 cells per side', () {
      expect(GlowGridSession(seed: 1, level: 1).current.size, 3);
      expect(GlowGridSession(seed: 1, level: 4).current.size, 4);
      expect(GlowGridSession(seed: 1, level: 8).current.size, 5);
    });

    test('invalid moves do not change the board or move count', () {
      final session = GlowGridSession(seed: 17);
      final before = session.litCells;

      expect(session.toggle(-1), GlowGridMoveResult.invalid);
      expect(session.toggle(session.current.cellCount), GlowGridMoveResult.invalid);
      expect(session.moves, 0);
      expect(session.litCells, before);
      expect(session.completedBoards, 0);
    });

    test('a legal move toggles its cell and orthogonal neighbours', () {
      final session = GlowGridSession(seed: 17);
      final before = session.litCells;
      final index = List<int>.generate(session.current.cellCount, (i) => i)
          .firstWhere((i) => _afterToggle(before, session.current.size, i).isNotEmpty);

      expect(session.toggle(index), GlowGridMoveResult.changed);
      expect(session.litCells, _afterToggle(before, session.current.size, index));
      expect(session.moves, 1);
    });

    test('known solutions clear every round and completion is stable', () {
      final session = GlowGridSession(seed: 44);

      for (var round = 0; round < GlowGridSession.boardCount; round++) {
        expect(session.boardIndex, round);
        expect(session.progress, round / GlowGridSession.boardCount);
        final solution = _minimumSolution(session.current);
        expect(solution, isNotEmpty);

        for (var move = 0; move < solution.length; move++) {
          final result = session.toggle(solution[move]);
          expect(
            result,
            move == solution.length - 1
                ? GlowGridMoveResult.boardSolved
                : GlowGridMoveResult.changed,
          );
        }
      }

      expect(session.finished, isTrue);
      expect(session.completedBoards, GlowGridSession.boardCount);
      expect(session.progress, 1);
      final finalMoves = session.moves;
      expect(session.toggle(0), GlowGridMoveResult.invalid);
      expect(session.moves, finalMoves);
    });
  });
}

List<int> _minimumSolution(GlowGridBoard board) {
  final cellCount = board.cellCount;
  final target = board.litCells.fold<int>(0, (mask, cell) => mask | (1 << cell));
  var best = <int>[];
  var bestLength = cellCount + 1;

  for (var selection = 0; selection < (1 << cellCount); selection++) {
    final length = _bitCount(selection);
    if (length >= bestLength) continue;
    final lights = <int>{};
    for (var cell = 0; cell < cellCount; cell++) {
      if ((selection & (1 << cell)) != 0) {
        _toggle(lights, board.size, cell);
      }
    }
    final result = lights.fold<int>(0, (mask, cell) => mask | (1 << cell));
    if (result == target) {
      best = [
        for (var cell = 0; cell < cellCount; cell++)
          if ((selection & (1 << cell)) != 0) cell,
      ];
      bestLength = length;
    }
  }
  return best;
}

int _bitCount(int value) {
  var count = 0;
  for (var bits = value; bits != 0; bits &= bits - 1) {
    count++;
  }
  return count;
}

Set<int> _afterToggle(Set<int> before, int size, int index) {
  final result = Set<int>.from(before);
  _toggle(result, size, index);
  return result;
}

void _toggle(Set<int> cells, int size, int index) {
  final row = index ~/ size;
  final column = index % size;
  for (final cell in <int>[
    index,
    if (row > 0) index - size,
    if (row < size - 1) index + size,
    if (column > 0) index - 1,
    if (column < size - 1) index + 1,
  ]) {
    if (!cells.add(cell)) cells.remove(cell);
  }
}
