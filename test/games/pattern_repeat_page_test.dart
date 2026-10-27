import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/pattern_repeat/pattern_repeat_page.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('fits ${size.width}x${size.height} without scrolling',
        (tester) async {
      var completed = false;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: PatternRepeatPage(launch: GameLaunch(
          level: 1,
          mode: GamePlayMode.neuron,
          onComplete: (_) => completed = true,
        )),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('WATCH THE PATTERN'), findsOneWidget);
      expect(find.byKey(const ValueKey('pattern-status')), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(completed, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
