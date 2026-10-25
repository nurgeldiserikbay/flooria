import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/signal_guard/signal_guard_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Signal Guard fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: SignalGuardPage(
        onComplete: () {}, onSessionEnd: (_, __) {},
      )));
      expect(find.text('Signal Guard'), findsOneWidget);
      expect(find.text('Tap the star. Ignore the ring.'), findsOneWidget);
      expect(find.byKey(const ValueKey('signal-card')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('signal-card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const ValueKey('signal-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
