import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/tower_tactics/tower_tactics_page.dart';

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('fits ${size.width}x${size.height} without page scrolling',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var completed = 0;
      var sessions = 0;

      await tester.pumpWidget(MaterialApp(
        home: TowerTacticsPage(
          floor: 2,
          onComplete: () => completed++,
          onSessionEnd: (_, __) => sessions++,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tower Tactics'), findsOneWidget);
      expect(find.text('Tap a stack, then a peg'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
      expect(completed, 0);
      expect(sessions, 0);

      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
