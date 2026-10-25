import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/arrow_orbit/arrow_orbit_engine.dart';
import 'package:flooria/games/arrow_orbit/arrow_orbit_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Arrow Orbit fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ArrowOrbitPage(
        floor: 1,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));

      expect(find.text('Arrow Orbit'), findsOneWidget);
      expect(find.textContaining('Rotation 1 of 5'), findsOneWidget);
      for (var index = 0; index < 16; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('arrow-orbit-cell-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final expected = OrbitSession(seed: 49979687);
      await tester.tap(find.byKey(
        ValueKey('arrow-orbit-cell-${expected.current.answerIndex}'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rotation 2 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('finishing reports results once', (tester) async {
    var completions = 0;
    var completedRounds = 0;
    var mistakes = -1;
    final expected = OrbitSession(seed: 49979687);
    await tester.pumpWidget(MaterialApp(home: ArrowOrbitPage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (rounds, slips) {
        completedRounds = rounds;
        mistakes = slips;
      },
    )));

    for (var round = 0; round < OrbitSession.roundCount; round++) {
      final answer = expected.current.answerIndex;
      await tester.tap(find.byKey(ValueKey('arrow-orbit-cell-$answer')));
      await tester.pumpAndSettle();
      expected.select(answer);
    }
    expect(find.text('Great sense of direction!'), findsOneWidget);
    expect(completions, 1);
    expect(completedRounds, OrbitSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
