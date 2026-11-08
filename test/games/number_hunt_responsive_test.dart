import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/number_hunt/number_hunt_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openNumberHunt(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('number_hunt');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(
        context, GameLaunch(level: level, mode: GamePlayMode.standalone,
          onComplete: (_) {}))),
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
      testWidgets('Number Hunt level $level at $size', (tester) async {
        viewport(tester, size);
        await openNumberHunt(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.byKey(const ValueKey('number-hunt-board-state')), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Number Hunt announces wrong guesses and round progress',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openNumberHunt(tester, 1);
    final engine = NumberHuntEngine.forLevel(1);
    final board = find.byKey(const ValueKey('number-hunt-board-state'));
    final target = engine.currentRound.targetIndex;
    final wrong = target == 0 ? 1 : 0;
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Find number ${engine.currentRound.target}'));

    await tester.tap(find.byKey(ValueKey('number-cell-$wrong')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Not this one'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 mistakes'));
    expect(tester.widget<Semantics>(
      find.descendant(of: find.byKey(ValueKey('number-cell-$wrong')),
        matching: find.byType(Semantics)).first).properties.label,
      contains('incorrect choice'));

    await tester.tap(find.byKey(ValueKey('number-cell-$target')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Round 2 of ${engine.rounds.length}'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Hunt honors reduced motion', (tester) async {
    await openNumberHunt(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('number-cell-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
