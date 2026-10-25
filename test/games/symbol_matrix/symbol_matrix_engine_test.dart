import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/symbol_matrix/symbol_matrix_engine.dart';

void main() {
  group('SymbolMatrixSession', () {
    test('seeded matrix has one exact answer across every attribute', () {
      for (var seed = 0; seed < 500; seed++) {
        final session = SymbolMatrixSession(seed: seed);
        expect(session.cells, hasLength(9));
        expect(session.cells.last, isNull);
        expect(session.cells.take(8), everyElement(isNotNull));
        expect(session.options, hasLength(SymbolMatrixSession.optionCount));
        expect(session.options.toSet(), hasLength(SymbolMatrixSession.optionCount));
        expect(session.answerIndex, inInclusiveRange(0, 3));

        final topLeft = session.cells[0]!;
        final topRight = session.cells[2]!;
        final bottomLeft = session.cells[6]!;
        final target = session.options[session.answerIndex];
        final domains = [4, 4, 3, 4];
        for (var attribute = 0; attribute < domains.length; attribute++) {
          final offset = attribute == 2 ? 1 : 0;
          final expected = (bottomLeft.valueAt(attribute) +
                  topRight.valueAt(attribute) -
                  topLeft.valueAt(attribute) -
                  offset) %
              domains[attribute];
          expect(target.valueAt(attribute) - offset, expected);
        }

        final matchingOptions = session.options.where((option) {
          for (var attribute = 0; attribute < domains.length; attribute++) {
            final offset = attribute == 2 ? 1 : 0;
            final expected = (bottomLeft.valueAt(attribute) +
                    topRight.valueAt(attribute) -
                    topLeft.valueAt(attribute) -
                    offset) %
                domains[attribute];
            if (option.valueAt(attribute) - offset != expected) return false;
          }
          return true;
        });
        expect(matchingOptions, hasLength(1));
        expect(matchingOptions.single, target);
      }
    });

    test('same seed repeats the same puzzles over the full session', () {
      final first = SymbolMatrixSession(seed: 9281);
      final second = SymbolMatrixSession(seed: 9281);
      for (var round = 0; round < SymbolMatrixSession.roundCount; round++) {
        expect(first.cells, second.cells);
        expect(first.options, second.options);
        expect(first.answerIndex, second.answerIndex);
        first.answer(first.answerIndex);
        second.answer(second.answerIndex);
        if (round < SymbolMatrixSession.roundCount - 1) {
          expect(first.nextRound(), isTrue);
          expect(second.nextRound(), isTrue);
        }
      }
    });

    test('invalid input and repeated answers do not change the round', () {
      final session = SymbolMatrixSession(seed: 17);
      expect(session.answer(-1), MatrixAnswerResult.invalid);
      expect(session.answer(session.options.length), MatrixAnswerResult.invalid);
      expect(session.attempts, 0);
      expect(session.nextRound(), isFalse);

      expect(session.answer(session.answerIndex), MatrixAnswerResult.correct);
      expect(session.attempts, 1);
      expect(session.nextRound(), isTrue);
      expect(session.answer(0), isNot(MatrixAnswerResult.invalid));
      final attempts = session.attempts;
      expect(session.answer(1), MatrixAnswerResult.invalid);
      expect(session.attempts, attempts);
      expect(session.mistakes + session.correctAnswers, attempts);
    });

    test('completion and pass threshold are measured from six answers', () {
      final passing = SymbolMatrixSession(seed: 22);
      for (var round = 0; round < SymbolMatrixSession.roundCount; round++) {
        final answer = round < 4
            ? passing.answerIndex
            : (passing.answerIndex + 1) % passing.options.length;
        final result = passing.answer(answer);
        if (round < SymbolMatrixSession.roundCount - 1) {
          expect(result,
              answer == passing.answerIndex
                  ? MatrixAnswerResult.correct
                  : MatrixAnswerResult.incorrect);
          expect(passing.nextRound(), isTrue);
        } else {
          expect(result, MatrixAnswerResult.sessionComplete);
        }
      }
      expect(passing.complete, isTrue);
      expect(passing.passed, isTrue);
      expect(passing.correctAnswers, 4);
      expect(passing.mistakes, 2);
      expect(passing.nextRound(), isFalse);
      expect(passing.answer(0), MatrixAnswerResult.invalid);

      final failing = SymbolMatrixSession(seed: 22);
      for (var round = 0; round < SymbolMatrixSession.roundCount; round++) {
        final answer = round < 3
            ? failing.answerIndex
            : (failing.answerIndex + 1) % failing.options.length;
        failing.answer(answer);
        if (round < SymbolMatrixSession.roundCount - 1) failing.nextRound();
      }
      expect(failing.complete, isTrue);
      expect(failing.passed, isFalse);
      expect(failing.correctAnswers, 3);
    });
  });
}
