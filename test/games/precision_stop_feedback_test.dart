import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openPrecision(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('precision_stop');
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
      testWidgets('Precision Stop level $level at $size', (tester) async {
        viewport(tester, size);
        await openPrecision(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.byKey(const ValueKey('precision-clock-state')), findsOneWidget);
        expect(find.byKey(const ValueKey('precision-feedback')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Precision Stop announces the last stopped time and misses',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openPrecision(tester, 1);
    final clock = find.byKey(const ValueKey('precision-clock-state'));
    expect(tester.widget<Semantics>(clock).properties.label,
      contains('No stop recorded yet.'));
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(clock).properties.label,
      contains('Timer running'));
    await tester.tap(find.text('STOP'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(clock).properties.label,
      contains('Timer stopped'));
    expect(tester.widget<Semantics>(clock).properties.label,
      contains('Last stop at'));
    expect(tester.widget<Semantics>(clock).properties.label,
      contains('1 misses'));
    expect(find.textContaining('TOO EARLY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Precision Stop honors reduced motion', (tester) async {
    await openPrecision(tester, 1, reducedMotion: true);
    expect(tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('precision-clock-scale')),
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
