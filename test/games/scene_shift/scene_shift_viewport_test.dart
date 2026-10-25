import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/scene_shift/scene_shift_engine.dart';
import 'package:flooria/games/scene_shift/scene_shift_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Scene Shift fits $size in both phases', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: SceneShiftPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Scene Shift'), findsOneWidget);
      expect(find.text('Scene 1 of 5'), findsOneWidget);
      final expected = SceneShiftSession(seed: 104729, level: 1);
      final previewRect = tester.getRect(
        find.byKey(ValueKey('scene-tile-${expected.current.changedIndex}')),
      );
      expect(previewRect.left, greaterThanOrEqualTo(0));
      expect(previewRect.top, greaterThanOrEqualTo(0));
      expect(previewRect.right, lessThanOrEqualTo(size.width));
      expect(previewRect.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('scene-reveal')));
      await tester.pumpAndSettle();
      expect(find.text('FIND THE CHANGE'), findsOneWidget);
      final answerRect = tester.getRect(
        find.byKey(ValueKey('scene-tile-${expected.current.changedIndex}')),
      );
      expect(answerRect.bottom, lessThanOrEqualTo(size.height));
      await tester.tap(find.byKey(
        ValueKey('scene-tile-${expected.current.changedIndex}'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Scene 2 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion is reported once after four or more correct scenes',
      (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = SceneShiftSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: SceneShiftPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (finds, misses) {
          correct = finds;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < SceneShiftSession.roundCount; index++) {
      await tester.tap(find.byKey(const ValueKey('scene-reveal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
        ValueKey('scene-tile-${expected.current.changedIndex}'),
      ));
      await tester.pumpAndSettle();
      expected.reveal();
      expected.choose(expected.current.changedIndex);
    }

    expect(find.text('Change spotted!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, SceneShiftSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('below-pass session records result without earning completion',
      (tester) async {
    var completions = 0;
    var mistakes = 0;
    final expected = SceneShiftSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: SceneShiftPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => mistakes = misses,
      ),
    ));

    for (var index = 0; index < SceneShiftSession.roundCount; index++) {
      await tester.tap(find.byKey(const ValueKey('scene-reveal')));
      await tester.pumpAndSettle();
      final wrongIndex = expected.current.changedIndex == 0 ? 1 : 0;
      await tester.tap(find.byKey(ValueKey('scene-tile-$wrongIndex')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
        ValueKey('scene-tile-${expected.current.changedIndex}'),
      ));
      await tester.pumpAndSettle();
      expected.reveal();
      expected.choose(wrongIndex);
      expected.choose(expected.current.changedIndex);
    }

    expect(find.text('Give it another look'), findsOneWidget);
    expect(completions, 0);
    expect(mistakes, SceneShiftSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
