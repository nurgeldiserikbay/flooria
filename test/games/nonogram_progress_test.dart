import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openNonogram(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('nonogram');
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
      testWidgets('Nonogram level $level on $size', (tester) async {
        viewport(tester, size);
        await openNonogram(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('nonogram-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Nonogram explains fill, cross and clearing a cell',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openNonogram(tester, 1);
    final board = find.byKey(const ValueKey('nonogram-board-state'));
    final cell = find.byKey(const ValueKey('nonogram-cell-0'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 moves made'));

    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('CELL FILLED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 cells filled'));

    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('CELL CROSSED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 cells filled'));

    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('CELL CLEARED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('3 moves made'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nonogram honors reduced motion', (tester) async {
    await openNonogram(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('nonogram-cell-0'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: cell, matching: find.byType(AnimatedScale)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
