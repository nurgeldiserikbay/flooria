import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/zip_route/zip_route_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openZip(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('zip_route');
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
      testWidgets('Zip Route $level on $size', (tester) async {
        viewport(tester, size);
        await openZip(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('zip-cell-state-0')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Zip Route clearly distinguishes legal moves and blocked taps',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openZip(tester, 1);
    final engine = ZipRouteEngine.forLevel(1);
    final start = engine.position;
    final cell = start == 0 ? 1 : start - 1;
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('zip-cell-state-$start')),
    ).properties.label, contains('current position'));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('zip-cell-state-$cell')),
    ).properties.label, contains('available next step'));

    final blocked = start == 0 ? engine.side * engine.side - 1 : 0;
    await tester.tap(find.byKey(ValueKey('zip-cell-state-$blocked')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('CHOOSE A GLOWING NEIGHBOR'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('zip-cell-state-$cell')));
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('zip-cell-state-$cell')),
    ).properties.label, contains('current position'));
    expect(find.textContaining('KEEP GOING'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zip Route tile animation respects reduced motion',
      (tester) async {
    await openZip(tester, 1, reducedMotion: true);
    final cell = find.byKey(const ValueKey('zip-cell-state-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: cell, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
