import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/focus_finder/focus_finder_engine.dart';

void main() {
  group('FocusFinderSession', () {
    test('seeded rounds repeat and contain one conjunction target', () {
      final first = FocusFinderSession(seed: 781);
      final second = FocusFinderSession(seed: 781);

      expect(first.rounds.length, FocusFinderSession.roundCount);
      for (var index = 0; index < first.rounds.length; index++) {
        final a = first.rounds[index];
        final b = second.rounds[index];
        expect(a.target, b.target);
        expect(a.tokens, orderedEquals(b.tokens));
        expect(a.targetIndex, b.targetIndex);
        expect(
          a.tokens.where((token) => token.matches(a.target)),
          hasLength(1),
        );
        expect(a.tokens[a.targetIndex], a.target);
      }
    });

    test('invalid picks leave the round unchanged', () {
      final session = FocusFinderSession(seed: 29);

      expect(session.choose(-1), SearchPickResult.invalid);
      expect(session.choose(session.current.tokens.length),
          SearchPickResult.invalid);
      expect(session.round, 0);
      expect(session.mistakes, 0);
      expect(session.correctFinds, 0);
    });

    test('wrong pick counts a mistake without advancing', () {
      final session = FocusFinderSession(seed: 17);
      final wrongIndex = session.current.targetIndex == 0 ? 1 : 0;

      expect(session.choose(wrongIndex), SearchPickResult.incorrect);
      expect(session.round, 0);
      expect(session.mistakes, 1);
      expect(session.correctFinds, 0);
    });

    test('correct picks complete the session and reject later input', () {
      final session = FocusFinderSession(seed: 92);

      for (var index = 0; index < FocusFinderSession.roundCount; index++) {
        expect(
          session.choose(session.current.targetIndex),
          index == FocusFinderSession.roundCount - 1
              ? SearchPickResult.complete
              : SearchPickResult.correct,
        );
      }

      expect(session.finished, isTrue);
      expect(session.progress, 1);
      expect(session.correctFinds, FocusFinderSession.roundCount);
      expect(session.choose(0), SearchPickResult.invalid);
    });

    test('difficulty adds distractors without making the board impossible', () {
      final easy = FocusFinderSession(seed: 10, level: 1);
      final harder = FocusFinderSession(seed: 10, level: 4);

      for (var index = 0; index < FocusFinderSession.roundCount; index++) {
        expect(harder.rounds[index].tokens.length,
            greaterThan(easy.rounds[index].tokens.length));
        expect(
          harder.rounds[index].tokens
              .where((token) => token.matches(harder.rounds[index].target)),
          hasLength(1),
        );
      }
    });
  });
}
