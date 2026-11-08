import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openSignal(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('signal_guard');
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
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final level in const [1, 90]) {
      testWidgets('Signal Guard level $level at $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openSignal(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        final arena = find.byKey(const ValueKey('signal-arena-state'));
        expect(tester.widget<Semantics>(arena).properties.label,
          'Ready to start');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Progress describes trials and arena announces waiting',
      (tester) async {
    await openSignal(tester, 1);
    expect(find.byType(Semantics), findsWidgets);
    await tester.tap(find.text('START'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('signal-arena-state')),
    ).properties.label, 'Wait for the next signal');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced-motion disables arena and strip animation',
      (tester) async {
    await openSignal(tester, 1, reducedMotion: true);
    final arena = find.byKey(const ValueKey('signal-arena-state'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: arena, matching: find.byType(AnimatedContainer)),
    ).duration, Duration.zero);
    final strip = find.byType(AnimatedContainer);
    expect(tester.widgetList<AnimatedContainer>(strip)
      .where((w) => w.constraints == null)
      .any((w) => w.duration == Duration.zero), isTrue);
  });
}
