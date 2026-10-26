import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/semantic_sort/semantic_sort_engine.dart';

void main() {
  group('SemanticSortSession', () {
    test('same seed generates the same category rounds and item order', () {
      final first = SemanticSortSession(seed: 27, level: 12);
      final second = SemanticSortSession(seed: 27, level: 12);

      expect(first.rounds.length, SemanticSortSession.roundCount);
      for (var roundIndex = 0; roundIndex < first.rounds.length; roundIndex++) {
        final a = first.rounds[roundIndex];
        final b = second.rounds[roundIndex];
        expect(a.leftCategory, b.leftCategory);
        expect(a.rightCategory, b.rightCategory);
        expect(
          a.items.map((item) => '${item.label}:${item.side.name}').toList(),
          b.items.map((item) => '${item.label}:${item.side.name}').toList(),
        );
      }
    });

    test('every round has balanced, unique items with fixed categories', () {
      for (var seed = 0; seed < 80; seed++) {
        final session = SemanticSortSession(seed: seed, level: 15);
        for (final round in session.rounds) {
          expect(round.leftCategory, isNot(round.rightCategory));
          expect(round.items.length, session.itemsPerRound);
          expect(
            round.items.where((item) => item.side == CategorySide.left).length,
            session.itemsPerRound ~/ 2,
          );
          expect(
            round.items.where((item) => item.side == CategorySide.right).length,
            session.itemsPerRound ~/ 2,
          );
          expect(
            round.items.map((item) => item.label).toSet().length,
            session.itemsPerRound,
          );
        }
      }
    });

    test('answer cannot be submitted twice before advancing', () {
      final session = SemanticSortSession(seed: 33);
      final side = session.currentItem.side;

      expect(session.answer(side), CategoryAnswer.correct);
      expect(session.answered, isTrue);
      expect(session.answer(side), CategoryAnswer.invalid);
      expect(session.correctAnswers, 1);
      expect(session.mistakes, 0);
      expect(session.itemIndex, 0);

      expect(session.advance(), isTrue);
      expect(session.answered, isFalse);
      expect(session.itemIndex, 1);
    });

    test('mistakes advance only after an answer and count toward threshold', () {
      final session = SemanticSortSession(seed: 58, level: 1);
      var wrongAnswers = 0;

      while (!session.finished) {
        final correctSide = session.currentItem.side;
        final side = wrongAnswers < 6
            ? (correctSide == CategorySide.left
                ? CategorySide.right
                : CategorySide.left)
            : correctSide;
        final answer = session.answer(side);
        expect(
          answer,
          side == correctSide
              ? CategoryAnswer.correct
              : CategoryAnswer.incorrect,
        );
        session.advance();
        wrongAnswers++;
      }

      expect(session.correctAnswers, session.totalItems - 6);
      expect(session.mistakes, 6);
      expect(session.passed, isTrue);
      expect(session.progress, 1);
      expect(session.answer(CategorySide.left), CategoryAnswer.invalid);
      expect(session.advance(), isFalse);
    });

    test('eight mistakes do not meet the 80 percent pass threshold', () {
      final session = SemanticSortSession(seed: 66);
      var wrongAnswers = 0;

      while (!session.finished) {
        final correctSide = session.currentItem.side;
        final side = wrongAnswers < 8
            ? (correctSide == CategorySide.left
                ? CategorySide.right
                : CategorySide.left)
            : correctSide;
        session.answer(side);
        session.advance();
        wrongAnswers++;
      }

      expect(session.correctAnswers, 22);
      expect(session.scoreToPass, 24);
      expect(session.passed, isFalse);
    });

    test('higher floors increase the number of items per category', () {
      final early = SemanticSortSession(seed: 9, level: 1);
      final middle = SemanticSortSession(seed: 9, level: 6);
      final late = SemanticSortSession(seed: 9, level: 14);

      expect(early.itemsPerRound, 6);
      expect(middle.itemsPerRound, 8);
      expect(late.itemsPerRound, 10);
      expect(early.rounds.every((round) => round.items.length == 6), isTrue);
      expect(late.rounds.every((round) => round.items.length == 10), isTrue);
    });
  });
}
