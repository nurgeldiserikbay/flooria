import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/glow_grid/glow_grid_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Glow Grid fits $size without scrolling or overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: GlowGridPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Glow Grid'), findsOneWidget);
      expect(find.text('Tap a light to toggle its neighbours.'), findsOneWidget);
      expect(find.text('LIGHTS LEFT'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      for (var index = 0; index < 9; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('glow-grid-cell-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('glow-grid-cell-0')));
      await tester.pumpAndSettle();
      expect(find.text('1 taps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
