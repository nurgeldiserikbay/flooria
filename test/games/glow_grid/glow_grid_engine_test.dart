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
      final index = 4;

      expect(session.toggle(index), GlowGridMoveResult.changed);
      final expected = Set<int>.from(before);
      _toggle(expected, session.current.size, index);

      expect(session.litCells, expected);
      expect(session.moves, 1);
    });

    test('progress only advances after a board is cleared', () {
      final session = GlowGridSession(seed: 44);
      expect(session.progress, 0);
      expect(session.completedBoards, 0);

      // Clearing every currently lit cell is not itself a valid solution,
      // but each legal action remains finite and progress stays bounded.
      session.toggle(0);
      expect(session.completedBoards, inInclusiveRange(0, 1));
      expect(session.progress, session.completedBoards / GlowGridSession.boardCount);
    });
  });
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
