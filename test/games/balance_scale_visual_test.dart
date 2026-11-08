import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/balance_scale/balance_scale_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openScale(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('balance_scale');
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
      testWidgets('Balance Scale level $level on $size', (tester) async {
        viewport(tester, size);
        await openScale(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('balance-progress-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Balance Scale explains the weight difference', (tester) async {
    viewport(tester, const Size(390, 844));
    await openScale(tester, 1);
    final engine = BalanceScaleEngine.forLevel(1);
    final progress = find.byKey(const ValueKey('balance-progress-state'));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('0 weights selected'));

    await tester.tap(find.byKey(const ValueKey('balance-weight-0')));
    engine.toggle(0);
    await tester.pump(const Duration(milliseconds: 90));

    expect(tester.widget<Semantics>(progress).properties.label,
      contains('1 weights selected'));
    final message = engine.total == engine.target
        ? 'SCALES ARE EVEN'
        : engine.total < engine.target
            ? 'NEED ${engine.difference} MORE KG'
            : 'REMOVE ${engine.difference} KG';
    expect(find.textContaining(message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Balance Scale respects reduced motion', (tester) async {
    await openScale(tester, 1, reducedMotion: true);
    final scale = find.byKey(const ValueKey('balance-scale-motion'));
    expect(tester.widget<TweenAnimationBuilder<double>>(scale).duration,
      Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
