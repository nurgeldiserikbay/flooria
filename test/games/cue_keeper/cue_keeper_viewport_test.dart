import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/cue_keeper/cue_keeper_engine.dart';
import 'package:flooria/games/cue_keeper/cue_keeper_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('cue stream fits on $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: CueKeeperPage(
          floor: 9,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Cue Keeper'), findsOneWidget);
      expect(find.byKey(const ValueKey('cue-keeper-stage')), findsOneWidget);
      expect(find.textContaining('When the'), findsOneWidget);
      expect(find.text('START STREAM'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('remembered cues complete and report the campaign once',
      (tester) async {
    var sessions = 0;
    var completions = 0;
    var reportedCorrect = -1;
    var reportedMisses = -1;
    final expected = CueKeeperSession(seed: 9 * 2027);

    await tester.pumpWidget(MaterialApp(
      home: CueKeeperPage(
        floor: 9,
        onComplete: () => completions++,
        onSessionEnd: (correct, misses) {
          sessions++;
          reportedCorrect = correct;
          reportedMisses = misses;
        },
      ),
    ));

    for (var round = 0; round < CueKeeperSession.roundCount; round++) {
      for (var cue = 0; cue < CueKeeperSession.cuesPerRound; cue++) {
        final label = expected.cueIndex < 0 ? 'START STREAM' : 'NEXT CUE';
        await tester.tap(find.text(label));
        await tester.pump();
        expect(expected.nextCue(), CueKeeperAdvanceResult.cueRevealed);
        if (round == 0 && cue == 0) {
          expect(find.textContaining('Watch each cue'), findsOneWidget);
          expect(find.textContaining('When the'), findsNothing);
        }
        if (expected.targetNow) {
          await tester.tap(find.byKey(const ValueKey('cue-keeper-act')));
          await tester.pump();
          expect(expected.actNow(), CueKeeperActionResult.correct);
        }
      }

      await tester.tap(find.text('END STREAM'));
      await tester.pump();
      expect(expected.nextCue(), CueKeeperAdvanceResult.streamComplete);
      if (round < CueKeeperSession.roundCount - 1) {
        expect(find.text('NEXT INTENTION'), findsOneWidget);
        await tester.tap(find.text('NEXT INTENTION'));
        await tester.pump();
        expect(expected.nextRound(), isTrue);
      }
    }

    expect(sessions, 1);
    expect(completions, 1);
    expect(reportedCorrect, CueKeeperSession.roundCount);
    expect(reportedMisses, 0);
    expect(find.text('LEVEL COMPLETE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
