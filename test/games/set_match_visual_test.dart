import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/set_match/set_match_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openSet(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('set_match');
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
      testWidgets('Set Match level $level on $size', (tester) async {
        viewport(tester, size);
        await openSet(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('set-board-progress')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Set Match describes cards and selection count', (tester) async {
    viewport(tester, const Size(390, 844));
    await openSet(tester, 1);
    final progress = find.byKey(const ValueKey('set-board-progress'));
    final engine = SetMatchEngine.forLevel(1);
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('0 of 3 cards selected'));

    final card = engine.cards[0]!;
    final description = tester.widget<Semantics>(
      find.byKey(const ValueKey('set-card-0'))).properties.label!;
    expect(description, contains('${card.count} shapes'));
    expect(description, contains(['red', 'green', 'blue'][card.color]));
    expect(description, contains(['oval', 'rectangle', 'triangle'][card.shape]));

    await tester.tap(find.byKey(const ValueKey('set-card-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('1 of 3 cards selected'));
    expect(find.textContaining('1 OF 3 CARDS SELECTED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Set Match animations honor reduced motion', (tester) async {
    await openSet(tester, 1, reducedMotion: true);
    final first = find.byKey(const ValueKey('set-card-0'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: first, matching: find.byType(AnimatedContainer)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
