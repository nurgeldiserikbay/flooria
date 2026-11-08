import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/sokoban/sokoban_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openSokoban(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('sokoban');
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
      testWidgets('Sokoban level $level at $size', (tester) async {
        viewport(tester, size);
        await openSokoban(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('sokoban-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Sokoban explains a blocked move and a valid step', (tester) async {
    viewport(tester, const Size(390, 844));
    await openSokoban(tester, 1);
    final state = find.byKey(const ValueKey('sokoban-board-state'));
    final engine = SokobanEngine.forLevel(1);
    expect(tester.widget<Semantics>(state).properties.label,
      contains('0 of ${engine.goals.length} crates on targets'));

    await tester.tap(find.byKey(const ValueKey('sokoban-move-left')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('GOOD STEP'), findsOneWidget);
    expect(tester.widget<Semantics>(state).properties.label,
      contains('1 moves made'));

    await tester.tap(find.byKey(const ValueKey('sokoban-move-left')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('BLOCKED'), findsOneWidget);
    expect(tester.widget<Semantics>(state).properties.label,
      contains('1 moves made'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sokoban honors reduced-motion mode', (tester) async {
    await openSokoban(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('sokoban-cell-40'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
