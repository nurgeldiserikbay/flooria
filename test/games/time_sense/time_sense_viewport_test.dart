import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/time_sense/time_sense_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Time Sense fits $size and starts a timing trial', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: TimeSensePage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Time Sense'), findsOneWidget);
      expect(find.text('Feel the interval. Stop from memory.'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('time-sense-start')));
      await tester.pump();
      expect(find.text('STOP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
