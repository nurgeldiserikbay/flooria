import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/symbol_matrix/symbol_matrix_engine.dart';
import 'package:flooria/games/symbol_matrix/symbol_matrix_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('matrix puzzle fits on $size without page scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: SymbolMatrixPage(
          floor: 12,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Symbol Matrix'), findsOneWidget);
      expect(find.text('ROUND 1 / 6'), findsOneWidget);
      expect(find.byKey(const ValueKey('symbol-matrix-board')), findsOneWidget);
      expect(find.byKey(const ValueKey('matrix-missing-cell')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('CHOOSE A TILE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('six choices end one session and report once', (tester) async {
    var sessions = 0;
    var completions = 0;
    final expectedSession = SymbolMatrixSession(seed: 3 * 2027);
    await tester.pumpWidget(MaterialApp(
      home: SymbolMatrixPage(
        floor: 3,
        onComplete: () => completions++,
        onSessionEnd: (_, __) => sessions++,
      ),
    ));

    for (var round = 0; round < 6; round++) {
      final answerIndex = expectedSession.answerIndex;
      await tester.tap(find.byKey(ValueKey('matrix-choice-$answerIndex')));
      await tester.pump();
      expectedSession.answer(answerIndex);
      if (round < 5) {
        expect(find.text('NEXT MATRIX'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('symbol-matrix-action')));
        await tester.pump();
        expectedSession.nextRound();
      }
    }

    expect(sessions, 1);
    expect(completions, 1);
    expect(find.textContaining('Session '), findsOneWidget);
    expect(find.text('ROUND 6 / 6'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey(
        'matrix-choice-${expectedSession.answerIndex}')));
    await tester.pump();
    expect(sessions, 1);
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });
}
