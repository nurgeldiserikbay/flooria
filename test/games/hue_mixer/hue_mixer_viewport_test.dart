import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/hue_mixer/hue_mixer_engine.dart';
import 'package:flooria/games/hue_mixer/hue_mixer_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Hue Mixer fits $size with target, mix and ratios visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const floor = 15;
      await tester.pumpWidget(MaterialApp(
        home: HueMixerPage(
          floor: floor,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Hue Mixer'), findsOneWidget);
      expect(find.text('Blend 1 of 5'), findsOneWidget);
      final expected = HueMixerSession(
        seed: floor * 49979687,
        level: floor,
      );
      for (final key in <String>[
        'hue-target',
        'hue-preview',
        ...expected.current.ratioChoices.map((ratio) => 'hue-ratio-$ratio'),
        'hue-mixer-action',
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

  testWidgets('matching all targets reports completion only once',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var correct = -1;
    var misses = -1;
    const floor = 1;
    final expected = HueMixerSession(seed: 49979687, level: floor);

    await tester.pumpWidget(MaterialApp(
      home: HueMixerPage(
        floor: floor,
        onComplete: () => completions++,
        onSessionEnd: (answers, mistakes) {
          correct = answers;
          misses = mistakes;
        },
      ),
    ));

    for (var index = 0; index < HueMixerSession.roundCount; index++) {
      final ratio = expected.current.targetFirstPercent;
      await tester.tap(find.byKey(ValueKey('hue-ratio-$ratio')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hue-mixer-action')));
      await tester.pump();
      expected.submit(ratio);

      await tester.tap(find.byKey(const ValueKey('hue-mixer-action')));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('Color artist!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, HueMixerSession.roundCount);
    expect(misses, 0);
    expect(tester.takeException(), isNull);
  });
}
