import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openMirror(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('mirror_beam');
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
      testWidgets('Mirror Beam level $level on $size', (tester) async {
        viewport(tester, size);
        await openMirror(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('mirror-board-state')), findsOneWidget);
        expect(find.byKey(const ValueKey('mirror-cell-state-22')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Mirror orientation and beam state update on rotation',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openMirror(tester, 1);
    final board = find.byKey(const ValueKey('mirror-board-state'));
    final mirror = find.byKey(const ValueKey('mirror-cell-state-22'));
    expect(tester.widget<Semantics>(board).properties.label,
        contains('2 mirrors, 0 turns'));
    expect(tester.widget<Semantics>(mirror).properties.label,
        contains('backslash orientation'));
    await tester.tap(find.byKey(const ValueKey('mirror-cell-22')));
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<Semantics>(mirror).properties.label,
        contains('slash orientation'));
    expect(tester.widget<Semantics>(board).properties.label,
        contains('1 turns'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mirror Beam honors reduced-motion settings',
      (tester) async {
    await openMirror(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('mirror-cell-state-22'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.widget<AnimatedRotation>(
      find.descendant(of: cell, matching: find.byType(AnimatedRotation)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
