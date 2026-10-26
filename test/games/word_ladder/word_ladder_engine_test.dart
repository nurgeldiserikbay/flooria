import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_ladder/word_ladder_engine.dart';

void main() {
  group('WordLadderSession', () {
    test('seeded puzzles and shuffled choices are deterministic', () {
      final first = WordLadderSession(seed: 77, level: 12);
      final second = WordLadderSession(seed: 77, level: 12);

      expect(first.rounds.length, WordLadderSession.roundCount);
      for (var round = 0; round < first.rounds.length; round++) {
        expect(first.rounds[round].words, second.rounds[round].words);
        expect(first.rounds[round].prompts.length,
            second.rounds[round].prompts.length);
        for (var rung = 0; rung < first.rounds[round].prompts.length; rung++) {
          expect(first.rounds[round].prompts[rung].choices,
              second.rounds[round].prompts[rung].choices);
        }
      }
    });

    test('every generated rung has one valid one-letter solution', () {
      for (var seed = 0; seed < 150; seed++) {
        final session = WordLadderSession(seed: seed, level: 12);
        for (final round in session.rounds) {
          expect(round.prompts.length, round.words.length - 1);
          for (var rung = 0; rung < round.prompts.length; rung++) {
            final prompt = round.prompts[rung];
            expect(prompt.currentWord, round.words[rung]);
            expect(prompt.correctWord, round.words[rung + 1]);
            expect(prompt.targetWord, round.words.last);
            expect(prompt.choices, contains(prompt.correctWord));
            expect(prompt.choices.toSet().length, prompt.choices.length);
            expect(prompt.choices.length, 4);
            expect(_letterDistance(prompt.currentWord, prompt.correctWord), 1);
          }
        }
      }
    });

    test('invalid choices do not change the current rung or score', () {
      final session = WordLadderSession(seed: 29);
      final prompt = session.prompt;

      expect(session.answer('not-an-option'), WordLadderAnswer.invalid);
      expect(session.roundIndex, 0);
      expect(session.rungIndex, 0);
      expect(session.solved, 0);
      expect(session.mistakes, 0);
      expect(session.prompt, same(prompt));
    });

    test('a wrong word ends only that ladder and records one miss', () {
      final session = WordLadderSession(seed: 41);
      final prompt = session.prompt;
      final wrong = prompt.choices.firstWhere((word) => word != prompt.correctWord);

      expect(session.answer(wrong), WordLadderAnswer.incorrect);
      expect(session.roundIndex, 1);
      expect(session.rungIndex, 0);
      expect(session.solved, 0);
      expect(session.mistakes, 1);
    });

    test('solving every rung completes the session and meets pass score', () {
      final session = WordLadderSession(seed: 105, level: 12);

      for (var round = 0; round < WordLadderSession.roundCount; round++) {
        final promptCount = session.current.prompts.length;
        for (var rung = 0; rung < promptCount; rung++) {
          final result = session.answer(session.prompt.correctWord);
          expect(
            result,
            round == WordLadderSession.roundCount - 1 &&
                    rung == promptCount - 1
                ? WordLadderAnswer.complete
                : WordLadderAnswer.correct,
          );
        }
      }

      expect(session.finished, isTrue);
      expect(session.passed, isTrue);
      expect(session.solved, WordLadderSession.roundCount);
      expect(session.mistakes, 0);
      expect(session.progress, 1);
      expect(session.answer('cat'), WordLadderAnswer.invalid);
    });

    test('floor increases the longest ladder gradually', () {
      final easy = WordLadderSession(seed: 11, level: 1);
      final medium = WordLadderSession(seed: 11, level: 6);
      final hard = WordLadderSession(seed: 11, level: 15);

      expect(easy.rounds.every((round) => round.prompts.length <= 2), isTrue);
      expect(medium.rounds.every((round) => round.prompts.length <= 3), isTrue);
      expect(hard.rounds.every((round) => round.prompts.length <= 5), isTrue);
      expect(hard.rounds.any((round) => round.prompts.length >= 4), isTrue);
    });
  });
}

int _letterDistance(String a, String b) {
  if (a.length != b.length) return a.length + b.length;
  var count = 0;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) count++;
  }
  return count;
}
