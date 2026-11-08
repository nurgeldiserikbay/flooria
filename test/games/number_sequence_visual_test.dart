import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/number_sequence/number_sequence_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openSequence(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('number_sequence');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(
        context,
        GameLaunch(level: level, mode: GamePlayMode.standalone,
          onComplete: (_) {}),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Number Sequence level $level on $size', (tester) async {
        viewport(tester, size);
        await openSequence(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('sequence-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Number Sequence explains incorrect answers and next round',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openSequence(tester, 1);
    final board = find.byKey(const ValueKey('sequence-board-state'));
    final engine = NumberSequenceEngine.forLevel(1);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Round 1 of 5'));
    final wrong = engine.choices.firstWhere((choice) => choice != engine.answer);
    await tester.tap(find.byKey(ValueKey('sequence-choice-$wrong')));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.textContaining('NOT QUITE'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 incorrect attempts'));

    await tester.tap(find.byKey(ValueKey('sequence-choice-${engine.answer}')));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.textContaining('GREAT ANSWER'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Round 2 of 5'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Sequence honors reduced-motion mode',
      (tester) async {
    await openSequence(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('sequence-board-state'));
    expect(tester.widget<AnimatedSwitcher>(
      find.descendant(of: board, matching: find.byType(AnimatedSwitcher)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
