import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/word_forge/word_forge_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Word Forge fits $size without page scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: WordForgePage(
        onComplete: () {}, onSessionEnd: (_, __) {},
      )));
      expect(find.text('Word Forge'), findsOneWidget);
      expect(find.text('YOUR WORD'), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('CHECK'));
      await tester.pump();
      expect(find.text('Choose every letter before checking.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
