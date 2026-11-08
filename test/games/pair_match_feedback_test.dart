import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/pair_match/pair_match_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openPairs(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('pair_match');
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
      testWidgets('Pair Match level $level at $size', (tester) async {
        viewport(tester, size);
        await openPairs(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('pair-board-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Pair Match explains flips and matching pairs', (tester) async {
    viewport(tester, const Size(390, 844));
    await openPairs(tester, 1);
    final engine = PairMatchEngine.forLevel(1);
    final board = find.byKey(const ValueKey('pair-board-state'));
    final partner = [for (var i = 1; i < engine.symbols.length; i++)
      if (engine.symbols[i] == engine.symbols.first) i].single;
    expect(partner, isNot(-1));
    expect(tester.widget<Semantics>(board).properties.label,
      contains('0 of ${engine.pairCount} pairs matched'));

    await tester.tap(find.byKey(const ValueKey('pair-card-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('ONE CARD REVEALED'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 cards revealed'));

    await tester.tap(find.byKey(ValueKey('pair-card-$partner')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('MATCH FOUND'), findsOneWidget);
    expect(tester.widget<Semantics>(board).properties.label,
      contains('1 of ${engine.pairCount} pairs matched'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pair Match honors reduced motion', (tester) async {
    await openPairs(tester, 1, reducedMotion: true);
    final card = find.byKey(const ValueKey('pair-card-0'));
    expect(tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(of: card, matching: find.byType(TweenAnimationBuilder<double>)).first,
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
