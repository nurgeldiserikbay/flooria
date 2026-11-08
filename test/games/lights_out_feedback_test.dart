import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/lights_out/lights_out_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openLights(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('lights_out');
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
      testWidgets('Lights Out level $level on $size', (tester) async {
        viewport(tester, size);
        await openLights(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('lights-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Lights Out explains the effect of each tap', (tester) async {
    viewport(tester, const Size(390, 844));
    await openLights(tester, 1);
    final engine = LightsOutEngine.forLevel(1);
    final board = find.byKey(const ValueKey('lights-board-state'));
    final before = engine.litCount;
    expect(tester.widget<Semantics>(board).properties.label,
      contains('$before of 25 lights on'));

    await tester.tap(find.byKey(const ValueKey('lights-cell-0')));
    await tester.pump(const Duration(milliseconds: 100));
    engine.press(0);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('${engine.litCount} of 25 lights on'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 taps used'));
    final message = engine.isCompleted ? 'ALL LIGHTS OUT'
        : engine.litCount < before ? 'FEWER LIGHTS ON'
        : engine.litCount > before ? 'MORE LIGHTS ON'
        : 'SAME NUMBER OF LIGHTS';
    expect(find.textContaining(message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lights Out honors reduced motion', (tester) async {
    await openLights(tester, 1, reducedMotion: true);
    final tile = find.byKey(const ValueKey('lights-cell-0'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: tile, matching: find.byType(AnimatedScale)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
