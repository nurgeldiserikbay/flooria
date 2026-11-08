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
      testWidgets('Target Sum $level on $size', (tester) async {
        viewport(tester, size);
        await openSum(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        final goal = TargetSumEngine.forLevel(level).currentRound;
        expect(tester.widget<Semantics>(
          find.byKey(const ValueKey('sum-target-state')),
        ).properties.label, contains('Make ${goal.target}'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Target Sum announces selection and supports undo',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openSum(tester, 1);
    final tile = find.byKey(const ValueKey('sum-tile-0-0'));
    final value = TargetSumEngine.forLevel(1).currentRound.values.first;
    expect(tester.widget<Semantics>(
      find.descendant(of: tile, matching: find.byType(Semantics)).first,
    ).properties.label, contains('Number $value'));
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('sum-target-state')),
    ).properties.label, contains('1 selected'));
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('sum-target-state')),
    ).properties.label, contains('0 selected'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Target Sum reduces target, slot and tile motion',
      (tester) async {
    await openSum(tester, 1, reducedMotion: true);
    final goal = find.byKey(const ValueKey('sum-target-state'));
    expect(tester.widget<AnimatedSwitcher>(
      find.descendant(of: goal, matching: find.byType(AnimatedSwitcher)).first,
    ).duration, Duration.zero);
    final tile = find.byKey(const ValueKey('sum-tile-0-0'));
    expect(tester.widget<AnimatedOpacity>(
      find.descendant(of: tile, matching: find.byType(AnimatedOpacity)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
