import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/code_breaker/code_breaker_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Code Breaker stays scroll-free on $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: CodeBreakerPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('CHECK CODE'), findsOneWidget);
      expect(find.byKey(const ValueKey('code-digit-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('players can compose a guess, undo, and restart', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CodeBreakerPage(
      onComplete: () {},
      onSessionEnd: (_, __) {},
    )));
    await tester.tap(find.byKey(const ValueKey('code-digit-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('code-digit-2')));
    await tester.pump();
    await tester.tap(find.byTooltip('Undo symbol'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('code-digit-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('code-digit-4')));
    await tester.pump();
    await tester.tap(find.text('CHECK CODE'));
    await tester.pump();
    expect(find.text('1 / 7'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 / 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
