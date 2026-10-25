import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/focus_finder/focus_finder_engine.dart';
import 'package:flooria/games/focus_finder/focus_finder_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Focus Finder fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: FocusFinderPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Focus Finder'), findsOneWidget);
      expect(find.text('Round 1 of 5'), findsOneWidget);
      final session = FocusFinderSession(seed: 104729, level: 1);
      final target = tester.getRect(
        find.byKey(ValueKey('focus-cell-${session.current.targetIndex}')),
      );
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.top, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(size.width));
      expect(target.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(
        ValueKey('focus-cell-${session.current.targetIndex}'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Round 2 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion is reported once after five targets', (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = FocusFinderSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: FocusFinderPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (finds, misses) {
          correct = finds;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < FocusFinderSession.roundCount; index++) {
      await tester.tap(find.byKey(
        ValueKey('focus-cell-${expected.current.targetIndex}'),
      ));
      await tester.pumpAndSettle();
      expected.choose(expected.current.targetIndex);
    }

    expect(find.text('Sharp eyes!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, FocusFinderSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
