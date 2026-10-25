import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/shell_shuffle/shell_shuffle_engine.dart';
import 'package:flooria/games/shell_shuffle/shell_shuffle_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Shell Shuffle fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: ShellShufflePage(
        floor: 1,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Shell Shuffle'), findsOneWidget);
      expect(find.textContaining('Round 1 of 5'), findsOneWidget);
      for (var slot = 0; slot < 3; slot++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('shell-shuffle-slot-$slot')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final expected = ShellShuffleSession(seed: 700001);
      await tester.tap(find.text('START SHUFFLE'));
      await tester.pump();
      for (var step = 0; step <= expected.current.swaps.length; step++) {
        await tester.pump(const Duration(milliseconds: 540));
      }
      await tester.pumpAndSettle();
      expect(find.text('Where did the star finish?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion is reported once after five correct tracks',
      (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = ShellShuffleSession(seed: 700001);
    await tester.pumpWidget(MaterialApp(home: ShellShufflePage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (tracks, slips) {
        correct = tracks;
        mistakes = slips;
      },
    )));

    for (var round = 0; round < ShellShuffleSession.roundCount; round++) {
      await tester.tap(find.text(
          round == 0 ? 'START SHUFFLE' : 'NEXT SHUFFLE'));
      await tester.pump();
      for (var step = 0; step <= expected.current.swaps.length; step++) {
        await tester.pump(const Duration(milliseconds: 540));
      }
      await tester.pumpAndSettle();

      final answer = expected.current.answerSlot;
      await tester.tap(find.byKey(ValueKey('shell-shuffle-slot-$answer')));
      await tester.pumpAndSettle();
      expected.choose(answer);
    }

    expect(find.text('Sharp eyes!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, ShellShuffleSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
