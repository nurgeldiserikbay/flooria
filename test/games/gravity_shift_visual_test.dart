import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openGravity(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('gravity_shift');
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
      testWidgets('Gravity Shift level $level on $size', (tester) async {
        viewport(tester, size);
        await openGravity(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('gravity-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Gravity Shift reports blocked direction', (tester) async {
    viewport(tester, const Size(390, 844));
    await openGravity(tester, 1);
    final board = find.byKey(const ValueKey('gravity-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Ball at row 6, column 1'));
    // The starting ball is at the left boundary for every level.
    await tester.tap(find.bySemanticsLabel('Tilt left'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('NO ROOM TO ROLL'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Ball at row 6, column 1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gravity Shift respects reduced-motion preference',
      (tester) async {
    await openGravity(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('gravity-board-state'));
    expect(tester.widget<AnimatedPositioned>(
      find.descendant(of: board, matching: find.byType(AnimatedPositioned)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
