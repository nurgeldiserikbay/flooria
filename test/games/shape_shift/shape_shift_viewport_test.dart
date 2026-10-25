import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/shape_shift/shape_shift_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Shape Shift fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ShapeShiftPage(
        onComplete: () {}, onSessionEnd: (_, __) {},
      )));
      expect(find.text('Shape Shift'), findsOneWidget);
      expect(find.text('REFERENCE SILHOUETTE'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
