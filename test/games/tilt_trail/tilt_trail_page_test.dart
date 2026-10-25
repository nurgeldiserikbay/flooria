import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/tilt_trail/tilt_trail_engine.dart';
import 'package:flooria/games/tilt_trail/tilt_trail_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Tilt Trail fits without page scrolling at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: TiltTrailPage(
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tilt-up')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('campaign completion is reported once after three trails',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 11;
    final expected = TiltTrailSession(seed: floor * 3253);
    var completionCalls = 0;
    var sessionCalls = 0;
    var reportedRounds = 0;
    var reportedMoves = 0;

    await tester.pumpWidget(MaterialApp(
      home: TiltTrailPage(
        floor: floor,
        onComplete: () => completionCalls++,
        onSessionEnd: (rounds, moves) {
          sessionCalls++;
          reportedRounds = rounds;
          reportedMoves = moves;
        },
      ),
    ));
    await tester.pump();

    for (var round = 0; round < TiltTrailSession.totalRounds; round++) {
      final route = List<TiltDirection>.from(expected.puzzle.solution);
      for (final direction in route) {
        await tester.tap(find.byKey(
          ValueKey<String>('tilt-${direction.name}'),
        ));
        await tester.pump();
        expected.tilt(direction);
      }

      expect(find.text('Star reached!'), findsOneWidget);
      await tester.tap(find.text('NEXT TRAIL'));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('All trails complete!'), findsOneWidget);
    expect(completionCalls, 1);
    expect(sessionCalls, 1);
    expect(reportedRounds, TiltTrailSession.totalRounds);
    expect(reportedMoves, expected.moves);
    expect(tester.takeException(), isNull);
  });
}
