import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/hue_sort/hue_sort_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String id, {
  int level = 1,
  bool reducedMotion = false,
}) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Builder(
        builder: (context) => game.buildPage(
          context,
          GameLaunch(
            level: level,
            mode: GamePlayMode.standalone,
            onComplete: (_) {},
          ),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 290));
}

void main() {
  for (final game in const ['tower_shift', 'hue_sort']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$game level $level on $size',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, game, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 290));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Tower Shift reveals safe pegs and rejects an illegal move',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'tower_shift');
    final a = find.byKey(const ValueKey('tower-peg-0'));
    final b = find.byKey(const ValueKey('tower-peg-1'));
    final c = find.byKey(const ValueKey('tower-peg-2'));

    await tester.tap(a);
    await tester.pump(const Duration(milliseconds: 195));
    expect(tester.widget<Semantics>(a).properties.label,
        contains('selected'));
    expect(tester.widget<Semantics>(b).properties.label,
        contains('valid destination'));
    expect(tester.widget<Semantics>(c).properties.label,
        contains('valid destination'));

    // Move the smallest disk onto B, then try the larger disk on A -> B.
    await tester.tap(b);
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Semantics>(b).properties.label,
        contains('1 disks'));

    await tester.tap(a);
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Semantics>(a).properties.label,
        contains('selected'));
    expect(tester.widget<Semantics>(b).properties.label,
        isNot(contains('valid destination')));
    expect(tester.widget<Semantics>(c).properties.label,
        contains('valid destination'));

    await tester.tap(b);
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Semantics>(a).properties.label,
        contains('selected'));
    expect(tester.widget<Semantics>(b).properties.label,
        contains('1 disks'));

    // Re-tapping the source clears the selection without moving a disk.
    await tester.tap(a);
    await tester.pump(const Duration(milliseconds: 190));
    expect(tester.widget<Semantics>(a).properties.label,
        isNot(contains('selected')));
    expect(tester.widget<Semantics>(c).properties.label,
        isNot(contains('valid destination')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hue Sort names fixed tiles and keeps selection in sync',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'hue_sort');
    final engine = HueSortEngine.forLevel(1);
    final firstFixed = engine.fixed.first;
    final movable = [
      for (var cell = 0; cell < engine.cellCount; cell++)
        if (!engine.isFixed(cell)) cell,
    ];
    expect(movable.length, greaterThanOrEqualTo(2));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('hue-tile-state-$firstFixed')),
    ).properties.label, contains('fixed reference'));

    final first = find.byKey(ValueKey('hue-cell-${movable[0]}'));
    final second = find.byKey(ValueKey('hue-cell-${movable[1]}'));
    await tester.tap(first);
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Semantics>(
      find.byKey(ValueKey('hue-tile-state-${movable[0]}')),
    ).properties.label, contains('selected'));

    await tester.tap(second);
    await tester.pump(const Duration(milliseconds: 470));
    expect(tester.widget<Text>(
      find.byKey(const ValueKey('hue-swaps')),
    ).data, '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tower and Hue Sort respect reduced-motion preference',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'tower_shift', reducedMotion: true);
    final peg = find.byKey(const ValueKey('tower-peg-0'));
    final pegFrame = tester.widget<AnimatedContainer>(
      find.descendant(of: peg, matching: find.byType(AnimatedContainer)),
    );
    expect(pegFrame.duration, Duration.zero);

    await _open(tester, 'hue_sort', reducedMotion: true);
    final tile = tester.widget<AnimatedPositioned>(
      find.byKey(const ValueKey('hue-tile-0')),
    );
    expect(tile.duration, Duration.zero);
    expect(tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byKey(const ValueKey('hue-cell-0')),
        matching: find.byType(AnimatedScale),
      ),
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
