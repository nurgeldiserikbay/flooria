import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/steady_hand/steady_hand_engine.dart';

void main() {
  group('SteadyHandSession', () {
    test('same seed and level create identical reachable trails', () {
      final first = SteadyHandSession(seed: 812, level: 7);
      final second = SteadyHandSession(seed: 812, level: 7);

      expect(first.rounds.length, SteadyHandSession.roundCount);
      for (var roundIndex = 0;
          roundIndex < SteadyHandSession.roundCount;
          roundIndex++) {
        final a = first.rounds[roundIndex];
        final b = second.rounds[roundIndex];
        expect(a.halfWidth, b.halfWidth);
        expect(a.points, b.points);
        expect(a.halfWidth, inInclusiveRange(.065, .13));
        for (var sample = 0; sample <= 42; sample++) {
          final x = SteadyHandRound.startX +
              (SteadyHandRound.finishX - SteadyHandRound.startX) * sample / 42;
          expect(a.centerYAt(x), inInclusiveRange(.22, .78));
        }
      }
    });

    test('following the generated centerline clears a trail', () {
      final session = SteadyHandSession(seed: 27);
      final trail = session.current;

      expect(session.begin(
        SteadyHandRound.startX,
        trail.centerYAt(SteadyHandRound.startX),
      ), isTrue);
      for (var sample = 1; sample <= 42; sample++) {
        final x = SteadyHandRound.startX +
            (SteadyHandRound.finishX - SteadyHandRound.startX) * sample / 42;
        expect(
          session.move(x, trail.centerYAt(x)),
          TrailMoveResult.tracking,
        );
      }
      expect(session.end(), isTrue);
      expect(session.completed, 1);
      expect(session.round, 1);
      expect(session.mistakes, 0);
      expect(session.attemptsLeft, SteadyHandSession.maxAttemptsPerRound);
    });

    test('off-lane movement ends an attempt and invalid input is ignored', () {
      final session = SteadyHandSession(seed: 54);
      final trail = session.current;
      final startY = trail.centerYAt(SteadyHandRound.startX);

      expect(session.begin(.5, startY), isFalse);
      expect(session.begin(SteadyHandRound.startX, startY), isTrue);
      expect(session.move(double.nan, .5), TrailMoveResult.ignored);
      expect(session.move(.4, 1.2), TrailMoveResult.ignored);
      expect(session.progress, SteadyHandRound.startX);
      expect(session.mistakes, 0);

      final x = .25;
      final outsideY = (trail.centerYAt(x) + trail.halfWidth + .05).clamp(0, 1);
      expect(session.move(x, outsideY.toDouble()), TrailMoveResult.leftLane);
      expect(session.active, isFalse);
      expect(session.mistakes, 1);
      expect(session.attemptsLeft, 2);
      expect(session.move(.5, .5), TrailMoveResult.ignored);
    });

    test('three misses advance the trail, and four cleared trails pass', () {
      final session = SteadyHandSession(seed: 3);
      for (var attempt = 0;
          attempt < SteadyHandSession.maxAttemptsPerRound;
          attempt++) {
        final trail = session.current;
        expect(session.begin(
          SteadyHandRound.startX,
          trail.centerYAt(SteadyHandRound.startX),
        ), isTrue);
        expect(session.move(.3, 0), TrailMoveResult.leftLane);
        expect(session.round, attempt == 2 ? 1 : 0);
      }
      expect(session.mistakes, 3);

      while (!session.finished) {
        final trail = session.current;
        expect(session.begin(
          SteadyHandRound.startX,
          trail.centerYAt(SteadyHandRound.startX),
        ), isTrue);
        for (var sample = 1; sample <= 42; sample++) {
          final x = SteadyHandRound.startX +
              (SteadyHandRound.finishX - SteadyHandRound.startX) * sample / 42;
          expect(session.move(x, trail.centerYAt(x)), TrailMoveResult.tracking);
        }
        expect(session.end(), isTrue);
      }
      expect(session.completed, 4);
      expect(session.passed, isTrue);
      expect(session.end(), isFalse);
    });
  });
}
