import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/magnitude_mapper/magnitude_mapper_engine.dart';
import 'package:flooria/games/magnitude_mapper/magnitude_mapper_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Magnitude Mapper fits $size with controls visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: MagnitudeMapperPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Magnitude Mapper'), findsOneWidget);
      expect(find.text('Number 1 of 6'), findsOneWidget);
      expect(find.text('FIND THIS VALUE'), findsOneWidget);

      for (final key in const [
        ValueKey('magnitude-slider'),
        ValueKey('magnitude-submit'),
      ]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('magnitude-slider')),
      );
      slider.onChanged!(.25);
      await tester.pump();
      expect(find.text('Your estimate: 25'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('accurate placements report completion once', (tester) async {
    var completions = 0;
    var accuratePlacements = -1;
    var mistakes = -1;
    final expected = MagnitudeMapperSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MagnitudeMapperPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (accurate, misses) {
          accuratePlacements = accurate;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < MagnitudeMapperSession.roundCount; index++) {
      final targetPosition = expected.current.targetPosition;
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('magnitude-slider')),
      );
      slider.onChanged!(targetPosition);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('magnitude-submit')));
      await tester.pumpAndSettle();
      expected.setGuess(targetPosition);
      expected.submit();
    }

    expect(find.text('Great sense of scale!'), findsOneWidget);
    expect(completions, 1);
    expect(accuratePlacements, MagnitudeMapperSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('low score records misses without awarding completion',
      (tester) async {
    var completions = 0;
    var recordedMistakes = -1;
    final expected = MagnitudeMapperSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MagnitudeMapperPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => recordedMistakes = misses,
      ),
    ));

    for (var index = 0; index < MagnitudeMapperSession.roundCount; index++) {
      final targetPosition = expected.current.targetPosition;
      final wrongPosition = targetPosition < .5 ? 1.0 : 0.0;
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('magnitude-slider')),
      );
      slider.onChanged!(wrongPosition);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('magnitude-submit')));
      await tester.pumpAndSettle();
      expected.setGuess(wrongPosition);
      expected.submit();
    }

    expect(find.text('Try the number line again'), findsOneWidget);
    expect(completions, 0);
    expect(recordedMistakes, MagnitudeMapperSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
