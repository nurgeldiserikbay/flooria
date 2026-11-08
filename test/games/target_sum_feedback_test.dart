import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/target_sum/target_sum_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openSum(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('target_sum');
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
      testWidgets('Target Sum level $level at $size', (tester) async {
        viewport(tester, size);
        await openSum(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('sum-target-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Target Sum explains selection and removal', (tester) async {
    viewport(tester, const Size(390, 844));
    await openSum(tester, 1);
    final engine = TargetSumEngine.forLevel(1);
    final state = find.byKey(const ValueKey('sum-target-state'));
    expect(tester.widget<Semantics>(state).properties.label,
      contains('Round 1 of ${engine.rounds.length}'));

    await tester.tap(find.byKey(const ValueKey('sum-tile-0-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('1 OF ${engine.currentRound.picks} NUMBERS SELECTED'),
      findsOneWidget);
    expect(tester.widget<Semantics>(state).properties.label,
      contains('Current sum ${engine.currentRound.values.first}'));

    await tester.tap(find.byKey(const ValueKey('sum-tile-0-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('NUMBER REMOVED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Target Sum honors reduced motion', (tester) async {
    await openSum(tester, 1, reducedMotion: true);
    final state = find.byKey(const ValueKey('sum-target-state'));
    expect(tester.widget<AnimatedSwitcher>(
      find.descendant(of: state, matching: find.byType(AnimatedSwitcher)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
