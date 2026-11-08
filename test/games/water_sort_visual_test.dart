import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/water_sort/water_sort_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openWater(WidgetTester tester, int level, {bool reducedMotion = false}) async {
  final game = GameRegistry.byId('water_sort');
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(builder: (context) => game.buildPage(context,
        GameLaunch(level: level, mode: GamePlayMode.standalone, onComplete: (_) {}))),
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
      testWidgets('Water Sort level $level at $size', (tester) async {
        viewport(tester, size);
        await openWater(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('water-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Water Sort announces selection and successful pour', (tester) async {
    viewport(tester, const Size(390, 844));
    await openWater(tester, 1);
    final engine = WaterSortEngine.forLevel(1);
    final source = engine.tubes.indexWhere((tube) => tube.isNotEmpty);
    final destination = engine.tubes.indexWhere((tube) => tube.isEmpty);
    final board = find.byKey(const ValueKey('water-board-state'));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 pours made'));
    await tester.tap(find.byKey(ValueKey('water-tube-$source')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('SELECTED · CHOOSE A DESTINATION'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('Tube ${source + 1} selected'));
    await tester.tap(find.byKey(ValueKey('water-tube-$destination')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 pours made'));
    expect(find.textContaining('NICE POUR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Water Sort honors reduced-motion preference', (tester) async {
    await openWater(tester, 1, reducedMotion: true);
    final tube = find.byKey(const ValueKey('water-tube-0'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: tube, matching: find.byType(AnimatedScale)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
