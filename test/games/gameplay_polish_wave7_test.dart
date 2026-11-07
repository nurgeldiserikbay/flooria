import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/balance_scale/balance_scale_engine.dart';
import 'package:flooria/games/domino_chain/domino_chain_engine.dart';
import 'package:flooria/games/picture_assemble/picture_assemble_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String gameId, {
  int level = 1, bool reduceMotion = false,
}) async {
  final definition = GameRegistry.byId(gameId);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Builder(builder: (context) => definition.buildPage(
        context,
        GameLaunch(
          level: level,
          mode: GamePlayMode.standalone,
          onComplete: (_) {},
        ),
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 360));
}

void main() {
  for (final id in const [
    'picture_assemble', 'balance_scale', 'domino_chain',
  ]) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level on ${size.width}x${size.height}',
            (tester) async {
          _phone(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 360));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Picture Assembly highlights adjacent legal tiles and slides',
      (tester) async {
    _phone(tester, const Size(390, 844));
    await _open(tester, 'picture_assemble');
    final engine = PictureAssembleEngine.forLevel(1);
    final blank = engine.blank;
    final neighbor = blank % PictureAssembleEngine.side == 0
        ? blank + 1 : blank - 1;
    final tile = find.byKey(ValueKey('picture-cell-$neighbor'));
    expect(tile, findsOneWidget);
    expect(tester.widget<Semantics>(tile).properties.label,
        contains('can slide'));
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 250));
    final newBlank = find.byKey(ValueKey('picture-cell-$neighbor'));
    expect(tester.widget<Semantics>(newBlank).properties.label,
        'Empty space');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Balance Scale tilts when a weight is selected and explains error',
      (tester) async {
    _phone(tester, const Size(390, 844));
    await _open(tester, 'balance_scale');
    final engine = BalanceScaleEngine.forLevel(1);
    final weight = engine.weights.first;
    final button = find.byWidgetPredicate((widget) =>
        widget is ChunkyButton &&
        widget.semanticLabel == '$weight kilograms, not selected');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 330));
    expect(find.byKey(const ValueKey('balance-scale-motion')),
        findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is ChunkyButton &&
        widget.semanticLabel == '$weight kilograms, selected'),
        findsOneWidget);
    await tester.tap(find.text('CHECK BALANCE'));
    await tester.pump(const Duration(milliseconds: 370));
    expect(find.textContaining('ADD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Domino Chain accepts a matching tile with animated placement',
      (tester) async {
    _phone(tester, const Size(390, 844));
    await _open(tester, 'domino_chain');
    final engine = DominoChainEngine.forLevel(1);
    final tile = engine.tiles.firstWhere((item) =>
        item.left == engine.openValue || item.right == engine.openValue);
    await tester.tap(find.byKey(ValueKey('domino-choice-${tile.id}')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(ValueKey('domino-placed-${tile.id}')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('domino-open-end')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new motion is optional when reduced-motion is requested',
      (tester) async {
    _phone(tester, const Size(390, 844));

    await _open(tester, 'picture_assemble', reduceMotion: true);
    final pictureCell = find.byKey(const ValueKey('picture-cell-0'));
    final pictureScale = tester.widget<AnimatedScale>(
      find.descendant(of: pictureCell,
          matching: find.byType(AnimatedScale)));
    expect(pictureScale.duration, Duration.zero);

    await _open(tester, 'balance_scale', reduceMotion: true);
    final tilt = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('balance-scale-motion')));
    expect(tilt.duration, Duration.zero);

    await _open(tester, 'domino_chain', reduceMotion: true);
    final engine = DominoChainEngine.forLevel(1);
    final first = find.byKey(ValueKey(
        'domino-choice-${engine.tiles.first.id}'));
    final face = tester.widgetList<AnimatedContainer>(
      find.descendant(of: first,
          matching: find.byType(AnimatedContainer))).first;
    expect(face.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
