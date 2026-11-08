import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openTower(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('tower_shift');
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
      testWidgets('Tower Shift level $level at $size', (tester) async {
        viewport(tester, size);
        await openTower(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('tower-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Tower Shift announces selected peg and a legal move',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openTower(tester, 1);
    final board = find.byKey(const ValueKey('tower-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 of 3 disks on goal peg C'));
    await tester.tap(find.byKey(const ValueKey('tower-peg-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('PEG A SELECTED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Peg A selected'));
    await tester.tap(find.byKey(const ValueKey('tower-peg-2')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('GOOD MOVE'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 of 3 disks on goal peg C'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 moves made'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tower Shift honors reduced-motion mode', (tester) async {
    await openTower(tester, 1, reducedMotion: true);
    final peg = find.byKey(const ValueKey('tower-peg-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: peg, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
