import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/arrow_orbit/arrow_orbit_engine.dart';

void main() {
  group('OrbitRound', () {
    test('rotation maps every cell to one unique destination', () {
      for (var turns = 1; turns <= 3; turns++) {
        final destinations = <int>{
          for (var index = 0; index < 16; index++)
            OrbitRound.rotateIndex(index, 4, turns),
        };
        expect(destinations, hasLength(16));
      }
      expect(OrbitRound.rotateIndex(0, 4, 1), 3);
      expect(OrbitRound.rotateIndex(0, 4, 2), 15);
      expect(OrbitRound.rotateIndex(0, 4, 3), 12);
    });

    test('seeded rounds are repeatable and always solvable', () {
      final first = OrbitSession(seed: 845);
      final second = OrbitSession(seed: 845);
      expect(first.rounds.length, OrbitSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.clockwiseTurns, b.clockwiseTurns);
        expect(a.targetIndex, b.targetIndex);
        expect(OrbitRound.rotateIndex(
          a.answerIndex, a.size, a.clockwiseTurns,
        ), a.targetIndex);
      }
    });
  });

  group('OrbitSession', () {
    test('invalid input does not change state', () {
      final session = OrbitSession(seed: 31);
      expect(session.select(-1), OrbitMoveResult.invalid);
      expect(session.select(16), OrbitMoveResult.invalid);
      expect(session.roundIndex, 0);
      expect(session.mistakes, 0);
      expect(session.lastSelection, isNull);
    });

    test('wrong selection counts a slip and correct answer advances', () {
      final session = OrbitSession(seed: 92);
      final wrong = (session.current.answerIndex + 1) % 16;
      expect(session.select(wrong), OrbitMoveResult.incorrect);
      expect(session.mistakes, 1);
      expect(session.lastSelection, wrong);
      expect(session.select(session.current.answerIndex),
          OrbitMoveResult.roundSolved);
      expect(session.roundIndex, 1);
      expect(session.progress, 1 / OrbitSession.roundCount);
    });

    test('solves all rounds and rejects input after completion', () {
      final session = OrbitSession(seed: 9);
      for (var round = 0; round < OrbitSession.roundCount; round++) {
        expect(session.select(session.current.answerIndex),
            OrbitMoveResult.roundSolved);
      }
      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.select(0), OrbitMoveResult.invalid);
    });
  });
}
