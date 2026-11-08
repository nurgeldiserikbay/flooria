import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openTide(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('tide_shift');
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
  await tester.pump(const Duration(milliseconds: 120));
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
      testWidgets('Tide Shift level $level on $size', (tester) async {
        viewport(tester, size);
        await openTide(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('tide-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Tide Shift explains blocked steps and safe high ground',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openTide(tester, 1);
    final board = find.byKey(const ValueKey('tide-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Tide level 0. Player at row 6, column 1'));
    await tester.tap(find.byTooltip('Move down'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('EDGE OF MAP'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('row 6, column 1'));

    await tester.tap(find.byTooltip('Move right'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.textContaining('ON HIGH GROUND'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('row 6, column 2'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 steps taken'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tide Shift board honors reduced motion',
      (tester) async {
    await openTide(tester, 1, reducedMotion: true);
    final board = find.byKey(const ValueKey('tide-board-state'));
    final cells = tester.widgetList<AnimatedContainer>(
      find.descendant(of: board, matching: find.byType(AnimatedContainer)),
    ).toList();
    expect(cells, isNotEmpty);
    expect(cells.every((cell) => cell.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
  });
}
