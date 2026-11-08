import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/shape_turn/shape_turn_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openShape(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('shape_turn');
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
      testWidgets('Shape Turn $level on $size', (tester) async {
        viewport(tester, size);
        await openShape(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('shape-target-state')), findsOneWidget);
        expect(find.byKey(const ValueKey('shape-option-state-0')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Shape Turn option feedback does not disclose answers early',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openShape(tester, 1);
    final first = find.byKey(const ValueKey('shape-option-state-0'));
    expect(tester.widget<Semantics>(first).properties.label,
      'Option 1, Select option');
    final answer = ShapeTurnEngine.forLevel(1).currentRound.answer;
    await tester.tap(find.byKey(ValueKey('shape-option-0-$answer')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('shape-option-state-$answer')),
    ).properties.label, contains('Correct matching rotation'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shape Turn respects reduced-motion settings',
      (tester) async {
    await openShape(tester, 1, reducedMotion: true);
    final first = find.byKey(const ValueKey('shape-option-state-0'));
    expect(tester.widget<AnimatedOpacity>(
      find.descendant(of: first, matching: find.byType(AnimatedOpacity)),
    ).duration, Duration.zero);
    expect(tester.widget<AnimatedRotation>(
      find.descendant(of: first, matching: find.byType(AnimatedRotation)),
    ).duration, Duration.zero);
    final target = find.byKey(const ValueKey('shape-target-state'));
    expect(tester.widget<AnimatedSwitcher>(
      find.descendant(of: target, matching: find.byType(AnimatedSwitcher)),
    ).duration, Duration.zero);
  });
}
