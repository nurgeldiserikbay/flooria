import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/target_sum/target_sum_engine.dart';

void main() {
  group('TargetSumSession', () {
    test('seeded boards are repeatable and every target has a solution', () {
      final first = TargetSumSession(seed: 613, level: 1);
      final second = TargetSumSession(seed: 613, level: 1);
      final harder = TargetSumSession(seed: 613, level: 5);

      expect(first.boards, second.boards);
      expect(first.boards.length, TargetSumSession.boardCount);
      expect(first.boards.every((board) => board.tiles.length == 6), isTrue);
      expect(first.boards.every(_hasSolution), isTrue);
      expect(harder.boards.every((board) => board.chooseCount == 4), isTrue);
      expect(harder.boards.every((board) => board.tiles.length == 8), isTrue);
      expect(harder.boards.every(_hasSolution), isTrue);
    });

    test('invalid selections and incomplete submissions do not mutate state', () {
      final session = TargetSumSession(seed: 83);

      expect(session.toggle(-1), isFalse);
      expect(session.toggle(session.current.tiles.length), isFalse);
      expect(session.submit(), SumSubmitResult.invalid);
      expect(session.selected, isEmpty);
      expect(session.completedBoards, 0);
      expect(session.mistakes, 0);
    });

    test('does not allow selecting more tiles than the requested count', () {
      final session = TargetSumSession(seed: 10);
      for (var index = 0; index < session.current.chooseCount; index++) {
        expect(session.toggle(index), isTrue);
      }
      expect(session.toggle(session.current.chooseCount), isFalse);
      expect(session.selected.length, session.current.chooseCount);
      expect(session.toggle(0), isTrue);
      expect(session.selected.length, session.current.chooseCount - 1);
    });

    test('solving all boards completes once and records accurate progress', () {
      final session = TargetSumSession(seed: 501, level: 4);
      while (!session.finished) {
        final indices = _solutionIndices(session.current);
        for (final index in indices) {
          expect(session.toggle(index), isTrue);
        }
        expect(session.submit(), SumSubmitResult.correct);
      }

      expect(session.completedBoards, TargetSumSession.boardCount);
      expect(session.progress, 1);
      expect(session.mistakes, 0);
      expect(session.passed, isTrue);
      expect(session.submit(), SumSubmitResult.invalid);
      expect(session.toggle(0), isFalse);
    });

    test('six mistakes are allowed, seven prevent level completion', () {
      for (final mistakeCount in <int>[6, 7]) {
        final session = TargetSumSession(seed: 77);
        for (var mistake = 0; mistake < mistakeCount; mistake++) {
          final indices = _wrongSolutionIndices(session.current);
          for (final index in indices) {
            session.toggle(index);
          }
          expect(session.submit(), SumSubmitResult.wrong);
        }
        while (!session.finished) {
          for (final index in _solutionIndices(session.current)) {
            session.toggle(index);
          }
          expect(session.submit(), SumSubmitResult.correct);
        }
        expect(session.mistakes, mistakeCount);
        expect(session.passed, mistakeCount == 6);
      }
    });
  });
}

bool _hasSolution(TargetSumBoard board) => _solutionIndices(board).isNotEmpty;

List<int> _solutionIndices(TargetSumBoard board) {
  final result = <int>[];
  bool search(int start, int remaining, int sum, List<int> selected) {
    if (remaining == 0) {
      if (sum == board.target) {
        result.addAll(selected);
        return true;
      }
      return false;
    }
    for (var index = start; index <= board.tiles.length - remaining; index++) {
      if (search(index + 1, remaining - 1, sum + board.tiles[index],
          [...selected, index])) {
        return true;
      }
    }
    return false;
  }

  search(0, board.chooseCount, 0, []);
  return result;
}

List<int> _wrongSolutionIndices(TargetSumBoard board) {
  List<int>? wrong;
  bool search(int start, int remaining, int sum, List<int> selected) {
    if (remaining == 0) {
      if (sum != board.target) {
        wrong = selected;
        return true;
      }
      return false;
    }
    for (var index = start; index <= board.tiles.length - remaining; index++) {
      if (search(index + 1, remaining - 1, sum + board.tiles[index],
          [...selected, index])) {
        return true;
      }
    }
    return false;
  }

  search(0, board.chooseCount, 0, []);
  return wrong!;
}
