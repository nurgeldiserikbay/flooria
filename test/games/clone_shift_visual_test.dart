import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openClone(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('clone_shift');
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
      testWidgets('Clone Shift level $level on $size', (tester) async {
        viewport(tester, size);
        await openClone(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('clone-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Clone Shift describes mirrored steps and blocked moves',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openClone(tester, 1);
    final board = find.byKey(const ValueKey('clone-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Explorer 1 at row 5, column 1'));
    await tester.tap(find.byTooltip('Move left'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('BOTH BLOCKED'), findsOneWidget);
    await tester.tap(find.byTooltip('Move up'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('BOTH EXPLORERS MOVED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Explorer 1 at row 4, column 1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Clone Shift respects reduced-motion mode',
      (tester) async {
    await openClone(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('clone-board-state'));
    expect(tester.widget<AnimatedPositioned>(
      find.descendant(of: board, matching: find.byType(AnimatedPositioned)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
