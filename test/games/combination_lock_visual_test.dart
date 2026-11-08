import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openLock(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('combination_lock');
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
      testWidgets('Combination Lock level $level on $size', (tester) async {
        viewport(tester, size);
        await openLock(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('lock-progress-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Lock gives clues for empty input and duplicate digits',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openLock(tester, 1);
    final progress = find.byKey(const ValueKey('lock-progress-state'));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('0 digits filled'));
    await tester.tap(find.text('TRY CODE'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('FILL EVERY SLOT'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lock-key-1')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('1 digits filled'));
    await tester.tap(find.byKey(const ValueKey('lock-key-1')));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('EACH DIGIT CAN ONLY APPEAR ONCE'),
      findsOneWidget);
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('1 digits filled'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lock animations respect reduced motion', (tester) async {
    await openLock(tester, 1, reducedMotion: true);
    final slot = find.byKey(const ValueKey('lock-slot-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: slot, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
