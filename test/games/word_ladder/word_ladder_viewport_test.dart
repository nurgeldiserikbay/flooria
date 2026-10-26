import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_ladder/word_ladder_engine.dart';
import 'package:flooria/games/word_ladder/word_ladder_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Word Ladder fits $size with every choice visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: WordLadderPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Word Ladder'), findsOneWidget);
      expect(find.text('Ladder 1 of 6'), findsOneWidget);
      final expected = WordLadderSession(seed: 130363, level: 1);
      for (final choice in expected.prompt.choices) {
        final rect = tester.getRect(
          find.byKey(ValueKey('word-ladder-choice-$choice')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('solved session reports earned completion only once',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var solved = -1;
    var misses = -1;
    final expected = WordLadderSession(seed: 130363, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: WordLadderPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (wins, errors) {
          solved = wins;
          misses = errors;
        },
      ),
    ));

    for (var round = 0; round < WordLadderSession.roundCount; round++) {
      while (!expected.finished &&
          expected.rungIndex < expected.current.prompts.length) {
        final word = expected.prompt.correctWord;
        await tester.tap(find.byKey(ValueKey('word-ladder-choice-$word')));
        await tester.pump();
        expected.answer(word);
        if (!expected.finished) {
          await tester.tap(find.byKey(const ValueKey('word-ladder-continue')));
          await tester.pump();
        }
      }
    }

    expect(find.text('Word wizard!'), findsOneWidget);
    expect(completions, 1);
    expect(solved, WordLadderSession.roundCount);
    expect(misses, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missed ladders are recorded without completion',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var misses = -1;
    final expected = WordLadderSession(seed: 130363, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: WordLadderPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, errors) => misses = errors,
      ),
    ));

    for (var round = 0; round < WordLadderSession.roundCount; round++) {
      final prompt = expected.prompt;
      final wrong =
          prompt.choices.firstWhere((word) => word != prompt.correctWord);
      await tester.tap(find.byKey(ValueKey('word-ladder-choice-$wrong')));
      await tester.pump();
      expected.answer(wrong);
      if (!expected.finished) {
        await tester.tap(find.byKey(const ValueKey('word-ladder-continue')));
        await tester.pump();
      }
    }

    expect(find.text('Keep building those bridges'), findsOneWidget);
    expect(completions, 0);
    expect(misses, WordLadderSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
