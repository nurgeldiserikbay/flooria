import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/shell_shuffle/shell_shuffle_engine.dart';

void main() {
  group('ShellShuffleSession', () {
    test('seeded shuffles repeat and answer follows every swap', () {
      final first = ShellShuffleSession(seed: 1234);
      final second = ShellShuffleSession(seed: 1234);
      expect(first.rounds.length, ShellShuffleSession.roundCount);

      for (var round = 0; round < first.rounds.length; round++) {
        final a = first.rounds[round];
        final b = second.rounds[round];
        expect(a.cupCount, b.cupCount);
        expect(a.starCup, b.starCup);
        expect(a.swaps.length, b.swaps.length);
        expect(a.answerSlot, inInclusiveRange(0, a.cupCount - 1));
        for (var index = 0; index < a.swaps.length; index++) {
          expect(a.swaps[index].firstSlot, b.swaps[index].firstSlot);
          expect(a.swaps[index].secondSlot, b.swaps[index].secondSlot);
          expect(a.swaps[index].firstSlot, isNot(a.swaps[index].secondSlot));
        }
      }
    });

    test('invalid cup choices do not change session state', () {
      final session = ShellShuffleSession(seed: 17);
      expect(session.choose(-1), ShellPickResult.invalid);
      expect(session.choose(session.current.cupCount), ShellPickResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.mistakes, 0);
      expect(session.correctAnswers, 0);
    });

    test('incorrect choice counts a slip; correct cup advances', () {
      final session = ShellShuffleSession(seed: 91);
      final wrong = (session.current.answerSlot + 1) %
          session.current.cupCount;
      expect(session.choose(wrong), ShellPickResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.roundIndex, 0);
      expect(session.choose(session.current.answerSlot),
          ShellPickResult.correct);
      expect(session.correctAnswers, 1);
      expect(session.roundIndex, 1);
    });

    test('solves every round and rejects answers after completion', () {
      final session = ShellShuffleSession(seed: 42);
      for (var round = 0; round < ShellShuffleSession.roundCount; round++) {
        expect(session.choose(session.current.answerSlot),
            round == ShellShuffleSession.roundCount - 1
                ? ShellPickResult.complete
                : ShellPickResult.correct);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.correctAnswers, ShellShuffleSession.roundCount);
      expect(session.choose(0), ShellPickResult.invalid);
    });
  });
}
