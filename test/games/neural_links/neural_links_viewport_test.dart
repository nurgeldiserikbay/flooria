import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/neural_links/neural_links_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Neural Links fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: NeuralLinksPage(
        onComplete: () {}, onSessionEnd: (_, __) {},
      )));
      expect(find.text('Neural Links'), findsOneWidget);
      expect(find.textContaining('crossings'), findsOneWidget);
      expect(find.byKey(const ValueKey('neural-graph')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
