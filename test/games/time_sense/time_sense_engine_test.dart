import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/time_sense/time_sense_engine.dart';

void main() {
  group('TimeSenseSession', () {
    test('seeded target intervals repeat and grow gradually with level', () {
      final first = TimeSenseSession(seed: 908, level: 1);
      final second = TimeSenseSession(seed: 908, level: 1);
      final advanced = TimeSenseSession(seed: 908, level: 7);

      expect(first.rounds, second.rounds);
      expect(first.rounds.length, TimeSenseSession.roundCount);
      expect(first.rounds.every((round) => round.targetMillis >= 2500), isTrue);
      expect(first.rounds.every((round) => round.targetMillis <= 4000), isTrue);
      expect(advanced.rounds.every((round) => round.targetMillis <= 6000), isTrue);
    });

    test('rejects invalid durations without changing session state', () {
      final session = TimeSenseSession(seed: 25);

      expect(session.submit(0), isFalse);
      expect(session.submit(-10), isFalse);
      expect(session.submit(TimeSenseSession.maximumAttemptMillis + 1), isFalse);
      expect(session.round, 0);
      expect(session.results, isEmpty);
    });

    test('scores durations inside and outside the accuracy window', () {
      final round = TimeSenseRound(targetMillis: 4000);

      expect(round.isAccurate(3200), isTrue);
      expect(round.isAccurate(4800), isTrue);
      expect(round.isAccurate(3199), isFalse);
      expect(round.isAccurate(4801), isFalse);
    });

    test('records five rounds and passes at three accurate estimates', () {
      final session = TimeSenseSession(seed: 42);
      for (var index = 0; index < TimeSenseSession.roundCount; index++) {
        final target = session.current.targetMillis;
        final elapsed = index < TimeSenseSession.passScore
            ? target
            : target + session.current.toleranceMillis + 1;
        expect(session.submit(elapsed), isTrue);
      }

      expect(session.finished, isTrue);
      expect(session.accurateCount, TimeSenseSession.passScore);
      expect(session.progress, 1);
      expect(session.passed, isTrue);
      expect(session.submit(3000), isFalse);
    });

    test('two accurate estimates do not pass', () {
      final session = TimeSenseSession(seed: 42);
      for (var index = 0; index < TimeSenseSession.roundCount; index++) {
        final target = session.current.targetMillis;
        final elapsed = index < TimeSenseSession.passScore - 1
            ? target
            : target + session.current.toleranceMillis + 1;
        session.submit(elapsed);
      }

      expect(session.accurateCount, TimeSenseSession.passScore - 1);
      expect(session.passed, isFalse);
    });
  });
}
