import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/signal_guard/signal_guard_engine.dart';

void main() {
  group('SignalGuardSession', () {
    test('seeded sessions are repeatable with seven targets and five distractors', () {
      final first = SignalGuardSession(seed: 411);
      final second = SignalGuardSession(seed: 411);
      expect(first.sequence, second.sequence);
      expect(first.sequence.where((signal) => signal == SignalKind.target).length, 7);
      expect(first.sequence.where((signal) => signal == SignalKind.distractor).length, 5);
      expect(first.roundCount, 12);
    });

    test('correct taps and correct holds clear all trials with no errors', () {
      final session = SignalGuardSession(seed: 907);
      while (!session.finished) {
        if (session.currentSignal == SignalKind.target) {
          expect(session.tap(), isTrue);
        } else {
          expect(session.timeout(), isTrue);
        }
      }
      expect(session.correctResponses, 12);
      expect(session.errors, 0);
      expect(session.progress, 1);
      expect(session.passed, isTrue);
      expect(session.tap(), isFalse);
      expect(session.timeout(), isFalse);
    });

    test('false alarms and misses both count toward the pass limit', () {
      final session = SignalGuardSession(seed: 1234);
      for (var trial = 0; trial < session.roundCount; trial++) {
        final signal = session.currentSignal;
        final makeError = trial < 4;
        if (makeError) {
          if (signal == SignalKind.target) {
            session.timeout();
          } else {
            session.tap();
          }
        } else if (signal == SignalKind.target) {
          session.tap();
        } else {
          session.timeout();
        }
      }
      expect(session.finished, isTrue);
      expect(session.errors, 4);
      expect(session.passed, isFalse);
    });

    test('pass threshold accepts exactly three errors', () {
      final session = SignalGuardSession(seed: 67);
      for (var trial = 0; trial < session.roundCount; trial++) {
        final signal = session.currentSignal;
        final makeError = trial < 3;
        if (makeError) {
          if (signal == SignalKind.target) {
            session.timeout();
          } else {
            session.tap();
          }
        } else if (signal == SignalKind.target) {
          session.tap();
        } else {
          session.timeout();
        }
      }
      expect(session.errors, 3);
      expect(session.passed, isTrue);
    });
  });
}
