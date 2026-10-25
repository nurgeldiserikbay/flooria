import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/main.dart';
import 'package:flooria/ui/sliding_2048_board.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('2048 fits without vertical scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MergePage(
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Sliding2048Board), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
    });

    testWidgets('Number Trail answers fit without scroll at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: SequencePage(
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });
  }
}
