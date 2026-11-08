import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/domino_chain/domino_chain_engine.dart';
import 'package:flooria/ui/game_kit.dart';

Future<void> openDomino(WidgetTester tester, int level, {
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId('domino_chain');
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
      testWidgets('Domino Chain level $level on $size', (tester) async {
        viewport(tester, size);
        await openDomino(tester, level);
        expect(find.byType(GameScaffold), findsOneWidget);
        expect(find.text('LEVEL $level'), findsOneWidget);
        expect(find.byKey(const ValueKey('domino-chain-state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Domino Chain announces valid and invalid tiles',
      (tester) async {
    viewport(tester, const Size(390, 844));
    await openDomino(tester, 1);
    final progress = find.byKey(const ValueKey('domino-chain-state'));
    final engine = DominoChainEngine.forLevel(1);
    final valid = engine.tiles.firstWhere((t) =>
        t.left == engine.openValue || t.right == engine.openValue);
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('Open number ${engine.openValue}'));

    await tester.tap(find.byKey(ValueKey('domino-choice-${valid.id}')));
    engine.place(valid.id);
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.widget<Semantics>(progress).properties.label,
      contains('Open number ${engine.openValue}'));
    expect(find.textContaining('GOOD MATCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Domino Chain respects reduced-motion mode',
      (tester) async {
    await openDomino(tester, 1, reducedMotion: true);
    final valid = find.byType(AnimatedContainer);
    expect(valid, findsWidgets);
    expect(tester.widgetList<AnimatedContainer>(valid)
      .where((widget) => widget.duration != Duration.zero), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
