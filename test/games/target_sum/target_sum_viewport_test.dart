import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/target_sum/target_sum_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Target Sum fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: TargetSumPage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Target Sum'), findsOneWidget);
      expect(find.text('Build the target from number tiles.'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('target-sum-tile-0')));
      await tester.pump();
      expect(find.textContaining('selected sum'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
