import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/color_flood/color_flood_engine.dart';
import 'package:flooria/games/nonogram/nonogram_engine.dart';
import 'package:flooria/games/set_match/set_match_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester,
  String gameId, {
  int level = 1,
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId(gameId);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(
        builder: (context) => game.buildPage(context, GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        )),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 260));
}

void main() {
  for (final id in const ['nonogram', 'color_flood', 'set_match']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level fits ${size.width}x${size.height}',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 270));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Nonogram marks have tactile feedback and semantic state',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'nonogram');
    expect(NonogramEngine.side, 6);
    final tile = find.byKey(const ValueKey('nonogram-cell-0'));
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 210));
    final animated = tester.widget<AnimatedScale>(
      find.descendant(of: tile, matching: find.byType(AnimatedScale)),
    );
    expect(animated.scale, .96);
    final semantics = tester.widget<Semantics>(tile);
    expect(semantics.properties.label, contains('filled'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Color Flood new move plays board feedback and updates choice',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'color_flood');
    final engine = ColorFloodEngine.forLevel(1);
    final color = (engine.currentColor + 1) % engine.colorCount;
    expect(find.byKey(const ValueKey('flood-board-0')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('flood-color-$color')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('flood-board-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Find a Set selection and invalid trio are understandable',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'set_match');
    final deck = SetMatchEngine.forLevel(1).cards;
    var triple = <int>[];
    bool valid(List<MatchCard> cards) {
      for (final feature in <int Function(MatchCard)>[
        (c) => c.color,
        (c) => c.shape,
        (c) => c.count,
        (c) => c.fill,
      ]) {
        final distinct = cards.map(feature).toSet().length;
        if (distinct != 1 && distinct != 3) return false;
      }
      return true;
    }
    search: for (var i = 0; i < deck.length - 2; i++) {
      for (var j = i + 1; j < deck.length - 1; j++) {
        for (var k = j + 1; k < deck.length; k++) {
          if (!valid([deck[i]!, deck[j]!, deck[k]!])) {
            triple = [i, j, k];
            break search;
          }
        }
      }
    }
    expect(triple, hasLength(3));
    for (final index in triple) {
      await tester.tap(find.byKey(ValueKey('set-card-$index')));
      await tester.pump(const Duration(milliseconds: 70));
    }
    expect(find.textContaining('NOT A SET'), findsOneWidget);
    expect(find.byType(Shake), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all three visual animations respect reduced motion',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'nonogram', reducedMotion: true);
    final tile = find.byKey(const ValueKey('nonogram-cell-0'));
    final nonogramScale = tester.widget<AnimatedScale>(
      find.descendant(of: tile, matching: find.byType(AnimatedScale)),
    );
    expect(nonogramScale.duration, Duration.zero);

    await _open(tester, 'color_flood', reducedMotion: true);
    final color = find.byKey(const ValueKey('flood-color-0'));
    final floodScale = tester.widget<AnimatedScale>(
      find.descendant(of: color, matching: find.byType(AnimatedScale)),
    );
    expect(floodScale.duration, Duration.zero);

    await _open(tester, 'set_match', reducedMotion: true);
    final card = find.byKey(const ValueKey('set-card-0'));
    final setScale = tester.widget<AnimatedScale>(
      find.descendant(of: card, matching: find.byType(AnimatedScale)),
    );
    expect(setScale.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
