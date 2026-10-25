import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/nonogram/nonogram_engine.dart';

void main() {
  test('all generated puzzles have correct row and column clue totals', () {
    for (var seed = -25; seed < 130; seed++) {
      final session = NonogramSession(seed: seed);
      final second = NonogramSession(seed: seed);
      expect(session.solution, second.solution);
      expect(session.rowClues, second.rowClues);
      expect(session.columnClues, second.columnClues);
      expect(session.solution.length, 25);
      for (var row = 0; row < 5; row++) {
        expect(session.rowClues[row],
          NonogramSession.runs([
            for (var col = 0; col < 5; col++)
              session.solution[row * 5 + col],
          ]));
      }
      for (var col = 0; col < 5; col++) {
        expect(session.columnClues[col],
          NonogramSession.runs([
            for (var row = 0; row < 5; row++)
              session.solution[row * 5 + col],
          ]));
      }
    }
  });

  test('taps cycle unknown, filled, excluded, unknown', () {
    final s = NonogramSession(seed: 7);
    expect(s.cells[0], 0);
    expect(s.toggle(0), true);
    expect(s.cells[0], 1);
    expect(s.toggle(0), true);
    expect(s.cells[0], 2);
    expect(s.toggle(0), true);
    expect(s.cells[0], 0);
    expect(s.toggle(-1), false);
    expect(s.toggle(25), false);
    expect(s.check(), false); // Nothing painted.
    expect(s.checks, 0);
  });

  test('wrong submission preserves input and allows correction', () {
    final s = NonogramSession(seed: 3);
    final missing = s.solution.indexOf(true);
    final empty = s.solution.indexOf(false);
    expect(empty, greaterThanOrEqualTo(0));
    expect(s.toggle(empty), true);
    expect(s.check(), false);
    expect(s.mistakes, 1);
    expect(s.cells[empty], 1);
    expect(s.toggle(empty), true);
    for (var i = 0; i < 25; i++) {
      if (s.solution[i]) s.toggle(i);
    }
    expect(s.cells[missing], 1);
    expect(s.check(), true);
    expect(s.round, 1);
    expect(s.mistakes, 1);
  });

  test('all three stages can be solved, session reports correct totals', () {
    final s = NonogramSession(seed: 24);
    for (var round = 0; round < 3; round++) {
      expect(s.finished, false);
      for (var i = 0; i < 25; i++) {
        if (s.solution[i]) expect(s.toggle(i), true);
        else if (i.isEven) {
          expect(s.toggle(i), true);
          expect(s.toggle(i), true);
        }
      }
      expect(s.solved, true);
      expect(s.check(), true);
    }
    expect(s.finished, true);
    expect(s.round, 3);
    expect(s.checks, 3);
    expect(s.mistakes, 0);
    expect(s.toggle(0), false);
    expect(s.check(), false);
  });
}
