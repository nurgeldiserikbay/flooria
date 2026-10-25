import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/steady_hand/steady_hand_engine.dart';
import 'package:flooria/games/steady_hand/steady_hand_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Steady Hand fits $size and traces a lane', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reports = 0;

      await tester.pumpWidget(MaterialApp(
        home: SteadyHandPage(
          floor: 2,
          onComplete: () {},
          onSessionEnd: (_, __) => reports++,
        ),
      ));
      expect(find.text('Steady Hand'), findsOneWidget);
      expect(find.text('Trace the lane without crossing its edge.'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      final area = tester.getRect(find.byKey(const ValueKey('steady-hand-canvas')));
      final round = SteadyHandSession(seed: 2 * 104729, level: 2).current;
      final start = Offset(
        area.left + SteadyHandRound.startX * area.width,
        area.top + round.centerYAt(SteadyHandRound.startX) * area.height,
      );
      final gesture = await tester.startGesture(start);
      for (var sample = 1; sample <= 42; sample++) {
        final x = SteadyHandRound.startX +
            (SteadyHandRound.finishX - SteadyHandRound.startX) * sample / 42;
        await gesture.moveTo(Offset(
          area.left + x * area.width,
          area.top + round.centerYAt(x) * area.height,
        ));
      }
      await gesture.up();
      await tester.pump();

      expect(find.text('2 / 5'), findsOneWidget);
      expect(reports, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart resets a practice session', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SteadyHandPage(onComplete: () {}, onSessionEnd: (_, __) {}),
    ));
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart session'));
    await tester.pump();
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.textContaining('Mistakes: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing every trail reports completion once', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var reports = 0;
    var completions = 0;
    await tester.pumpWidget(MaterialApp(
      home: SteadyHandPage(
        floor: 2,
        onComplete: () => completions++,
        onSessionEnd: (cleared, misses) {
          reports++;
          expect(cleared, SteadyHandSession.roundCount);
          expect(misses, 0);
        },
      ),
    ));

    final generated = SteadyHandSession(seed: 2 * 104729, level: 2);
    for (final round in generated.rounds) {
      final area = tester.getRect(find.byKey(const ValueKey('steady-hand-canvas')));
      final gesture = await tester.startGesture(Offset(
        area.left + SteadyHandRound.startX * area.width,
        area.top + round.centerYAt(SteadyHandRound.startX) * area.height,
      ));
      for (var sample = 1; sample <= 42; sample++) {
        final x = SteadyHandRound.startX +
            (SteadyHandRound.finishX - SteadyHandRound.startX) * sample / 42;
        await gesture.moveTo(Offset(
          area.left + x * area.width,
          area.top + round.centerYAt(x) * area.height,
        ));
      }
      await gesture.up();
      await tester.pump();
    }

    expect(reports, 1);
    expect(completions, 1);
    expect(find.text('Steady all the way!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
