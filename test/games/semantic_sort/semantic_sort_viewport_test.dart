import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/semantic_sort/semantic_sort_engine.dart';
import 'package:flooria/games/semantic_sort/semantic_sort_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Semantic Sort fits $size with item and both groups visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: SemanticSortPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Semantic Sort'), findsOneWidget);
      expect(find.text('Category 1 of 5'), findsOneWidget);
      for (final key in <String>[
        'semantic-sort-item',
        'semantic-sort-left',
        'semantic-sort-right',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(size.width), reason: key);
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('perfect sorting reports earned completion once',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var correctAnswers = -1;
    var mistakes = -1;
    final expected = SemanticSortSession(seed: 32452843, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: SemanticSortPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (correct, errors) {
          correctAnswers = correct;
          mistakes = errors;
        },
      ),
    ));

    while (!expected.finished) {
      final side = expected.currentItem.side;
      await tester.tap(find.byKey(ValueKey('semantic-sort-${side.name}')));
      await tester.pump();
      expected.answer(side);

      await tester.tap(find.byKey(const ValueKey('semantic-sort-next')));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('Great sorting!'), findsOneWidget);
    expect(completions, 1);
    expect(correctAnswers, expected.totalItems);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
