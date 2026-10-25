import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/quick_count/quick_count_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Quick Count fits $size and completes a session', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reports = 0;

      await tester.pumpWidget(MaterialApp(home: QuickCountPage(
        onComplete: () {},
        onSessionEnd: (correct, total) {
          reports++;
          expect(total, 8);
          expect(correct, inInclusiveRange(0, 8));
        },
      )));
      expect(find.text('Quick Count'), findsOneWidget);
      expect(find.text('Glance at the dots. Estimate the amount.'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      for (var round = 0; round < 8; round++) {
        await tester.pump(const Duration(milliseconds: 1400));
        expect(find.text('${round + 1} / 8'), findsOneWidget);
        final firstChoice = find.byType(FilledButton).first;
        expect(firstChoice, findsOneWidget);
        expect(tester.widget<FilledButton>(firstChoice).onPressed, isNotNull);
        await tester.tap(firstChoice);
        await tester.pump();
        if (round < 7) {
          await tester.pump(const Duration(milliseconds: 430));
          expect(find.text('${round + 2} / 8'), findsOneWidget);
        }
      }

      expect(reports, 1);
      expect(find.textContaining('of 8 estimates were exact'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
