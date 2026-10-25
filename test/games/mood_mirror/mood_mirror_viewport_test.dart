import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mood_mirror/mood_mirror_engine.dart';
import 'package:flooria/games/mood_mirror/mood_mirror_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Mood Mirror fits $size with face and choices visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: MoodMirrorPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Mood Mirror'), findsOneWidget);
      expect(find.text('Face 1 of 6'), findsOneWidget);
      expect(find.text('READ THE EXPRESSION'), findsOneWidget);
      final session = MoodMirrorSession(seed: 104729, level: 1);
      for (var index = 0; index < session.current.choices.length; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('mood-choice-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);

      final answerIndex =
          session.current.choices.indexOf(session.current.emotion);
      await tester.tap(
          find.byKey(ValueKey('mood-choice-$answerIndex')));
      await tester.pumpAndSettle();
      expect(find.text('Face 2 of 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion callback fires after five correct readings',
      (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = MoodMirrorSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MoodMirrorPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (wins, misses) {
          correct = wins;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < MoodMirrorSession.roundCount; index++) {
      final answerIndex =
          expected.current.choices.indexOf(expected.current.emotion);
      await tester.tap(find.byKey(ValueKey('mood-choice-$answerIndex')));
      await tester.pumpAndSettle();
      expected.respond(expected.current.emotion);
    }

    expect(find.text('Thoughtful observer!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, MoodMirrorSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('low score records session without earning completion',
      (tester) async {
    var completions = 0;
    var recordedMistakes = 0;
    final expected = MoodMirrorSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MoodMirrorPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => recordedMistakes = misses,
      ),
    ));

    for (var index = 0; index < MoodMirrorSession.roundCount; index++) {
      final wrong = expected.current.choices.firstWhere(
        (emotion) => emotion != expected.current.emotion,
      );
      final answerIndex = expected.current.choices.indexOf(wrong);
      await tester.tap(find.byKey(ValueKey('mood-choice-$answerIndex')));
      await tester.pumpAndSettle();
      expected.respond(wrong);
    }

    expect(find.text('Try reading the cues again'), findsOneWidget);
    expect(completions, 0);
    expect(recordedMistakes, MoodMirrorSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
