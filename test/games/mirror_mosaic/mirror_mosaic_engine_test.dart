import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mirror_mosaic/mirror_mosaic_engine.dart';

void main() {
  group('MirrorMosaicSession', () {
    test('seeded patterns are reproducible and reflected exactly', () {
      final first = MirrorMosaicSession(seed: 814);
      final second = MirrorMosaicSession(seed: 814);

      expect(first.boards.length, MirrorMosaicSession.boardCount);
      for (var round = 0; round < first.boards.length; round++) {
        final a = first.boards[round];
        final b = second.boards[round];
        expect(a.axis, b.axis);
        expect(a.sourceCells, b.sourceCells);
        expect(a.targetCells, b.targetCells);
        expect(a.sourceCells, isNotEmpty);
        expect(a.targetCells.length, 2 + round ~/ 2);

        for (final source in a.sourceCells) {
          final row = source ~/ a.size;
          final column = source % a.size;
          final expected = a.axis == MirrorAxis.vertical
              ? row * a.size + a.size - 1 - column
              : (a.size - 1 - row) * a.size + column;
          expect(a.targetCells, contains(expected));
          expect(a.isPlayable(expected), isTrue);
        }
      }
    });

    test('source, axis and out-of-range cells are invalid inputs', () {
      final session = MirrorMosaicSession(seed: 8);
      final source = session.current.sourceCells.first;
      final axis = session.current.axis == MirrorAxis.vertical
          ? session.current.axisIndex
          : session.current.axisIndex * session.current.size;

      expect(session.toggle(source), MirrorMosaicMoveResult.invalid);
      expect(session.toggle(axis), MirrorMosaicMoveResult.invalid);
      expect(session.toggle(-1), MirrorMosaicMoveResult.invalid);
      expect(
        session.toggle(session.current.cellCount),
        MirrorMosaicMoveResult.invalid,
      );
      expect(session.selected, isEmpty);
      expect(session.mistakes, 0);
      expect(session.completedBoards, 0);
    });

    test('wrong selections can be undone without counting a second slip', () {
      final session = MirrorMosaicSession(seed: 11);
      final wrong = List<int>.generate(session.current.cellCount, (i) => i)
          .firstWhere((index) =>
              session.current.isPlayable(index) &&
              !session.current.targetCells.contains(index));

      expect(session.toggle(wrong), MirrorMosaicMoveResult.changed);
      expect(session.selected, contains(wrong));
      expect(session.mistakes, 1);
      expect(session.toggle(wrong), MirrorMosaicMoveResult.changed);
      expect(session.selected, isEmpty);
      expect(session.mistakes, 1);
    });

    test('matching every reflected pattern completes exactly five boards', () {
      final session = MirrorMosaicSession(seed: 92);

      for (var round = 0; round < MirrorMosaicSession.boardCount; round++) {
        expect(session.boardIndex, round);
        expect(session.progress, round / MirrorMosaicSession.boardCount);
        final targets = session.current.targetCells.toList();
        expect(targets.length, session.current.targetCount);

        for (var move = 0; move < targets.length; move++) {
          expect(
            session.toggle(targets[move]),
            move == targets.length - 1
                ? MirrorMosaicMoveResult.boardSolved
                : MirrorMosaicMoveResult.changed,
          );
        }
      }

      expect(session.finished, isTrue);
      expect(session.completedBoards, MirrorMosaicSession.boardCount);
      expect(session.progress, 1);
      expect(session.selected, isEmpty);
      expect(session.toggle(24), MirrorMosaicMoveResult.invalid);
    });
  });
}
