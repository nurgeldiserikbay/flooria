import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/balance_beam/balance_beam_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Balance Beam fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: BalanceBeamPage(
        onComplete: () {}, onSessionEnd: (_, __) {},
      )));
      expect(find.text('Balance Beam'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
