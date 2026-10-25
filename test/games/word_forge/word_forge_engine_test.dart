import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_forge/word_forge_engine.dart';

void main() {
  group('WordForgeSession', () {
    test('seeded puzzles are repeatable and have increasing word lengths', () {
      final first = WordForgeSession(seed: 8371);
      final second = WordForgeSession(seed: 8371);
      expect(first.roundCount, 3);
      for (var round = 0; round < first.roundCount; round++) {
        expect(first.puzzle.answer, second.puzzle.answer);
        expect(first.puzzle.clue, second.puzzle.clue);
        expect(first.puzzle.letters, second.puzzle.letters);
        expect(first.puzzle.letters.length, 5 + round);
        expect(_sorted(first.puzzle.letters), _sorted(first.puzzle.answer.split('')));
        expect(first.puzzle.letters.join(), isNot(first.puzzle.answer));
        if (round < 2) {
          _solve(first);
          _solve(second);
        }
      }
    });

    test('ignores invalid or duplicate tile selections and incomplete checks', () {
      final session = WordForgeSession(seed: 17);
      expect(session.select(-1), isFalse);
      expect(session.select(session.puzzle.letters.length), isFalse);
      expect(session.select(0), isTrue);
      expect(session.select(0), isFalse);
      expect(session.draft.length, 1);
      expect(session.submit(), WordForgeSubmitResult.incomplete);
      expect(session.submissions, 0);
      expect(session.mistakes, 0);
    });

    test('wrong complete word counts a mistake and remains editable', () {
      final session = WordForgeSession(seed: 993);
      for (var index = 0; index < session.puzzle.letters.length; index++) {
        expect(session.select(index), isTrue);
      }
      expect(session.draft, isNot(session.puzzle.answer));
      expect(session.submit(), WordForgeSubmitResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.submissions, 1);
      expect(session.submit(), WordForgeSubmitResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.submissions, 1);
      expect(session.draft.length, session.puzzle.answer.length);
      expect(session.removeLast(), isTrue);
      expect(session.draft.length, session.puzzle.answer.length - 1);
    });

    test('three correct words complete exactly once', () {
      final session = WordForgeSession(seed: 244);
      for (var round = 0; round < session.roundCount; round++) {
        _solve(session);
        expect(session.round, round + 1);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.mistakes, 0);
      expect(session.submit(), WordForgeSubmitResult.sessionComplete);
      expect(session.round, session.roundCount);
    });
  });
}

void _solve(WordForgeSession session) {
  final remaining = List<int>.generate(session.puzzle.letters.length, (i) => i);
  for (final target in session.puzzle.answer.split('')) {
    final index = remaining.firstWhere((candidate) =>
        session.puzzle.letters[candidate] == target);
    expect(session.select(index), isTrue);
    remaining.remove(index);
  }
  expect(session.submit(), isNot(WordForgeSubmitResult.incorrect));
}

List<String> _sorted(List<String> letters) => List<String>.of(letters)..sort();
