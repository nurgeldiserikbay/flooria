import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/rhyme_rally/rhyme_rally_engine.dart';
import 'package:flooria/games/rhyme_rally/rhyme_rally_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Rhyme Rally fits $size and completes the session',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reports = 0;
      var completions = 0;

      await tester.pumpWidget(MaterialApp(
        home: RhymeRallyPage(
          floor: 3,
          onComplete: () => completions++,
          onSessionEnd: (correct, mistakes) {
            reports++;
            expect(correct, RhymeRallySession.roundCount);
            expect(mistakes, 0);
          },
        ),
      ));
      expect(find.text('Rhyme Rally'), findsOneWidget);
      expect(find.text('WHICH WORD RHYMES WITH…?'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);

      final expected = RhymeRallySession(seed: 3 * 13579, level: 3);
      for (var index = 0; index < RhymeRallySession.roundCount; index++) {
        await tester.tap(find.byKey(ValueKey(
            'rhyme-option-${expected.rounds[index].correctIndex}')));
        await tester.pump();
      }

      expect(reports, 1);
      expect(completions, 1);
      expect(find.text('Rhyme star!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('practice result can restart without duplicate reporting',
      (tester) async {
    var reports = 0;
    await tester.pumpWidget(MaterialApp(
      home: RhymeRallyPage(
        onComplete: () {},
        onSessionEnd: (_, __) => reports++,
      ),
    ));
    for (var index = 0; index < RhymeRallySession.roundCount; index++) {
      await tester.tap(find.byKey(const ValueKey('rhyme-option-0')));
      await tester.pump();
    }
    expect(reports, 1);
    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pump();
    expect(find.text('1 / 10'), findsOneWidget);
    expect(reports, 1);
    expect(tester.takeException(), isNull);
  });
}
