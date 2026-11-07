import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/orbit_catch/orbit_catch_engine.dart';
import 'package:flooria/games/tide_shift/tide_shift_engine.dart';
import 'package:flooria/ui/game_kit.dart';

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String id, {
  int level = 1,
  bool reduceMotion = false,
}) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
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
  await tester.pump(const Duration(milliseconds: 270));
}

void main() {
  for (final id in const ['tide_shift', 'orbit_catch']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id fits ${size.width}x${size.height} at level $level',
            (tester) async {
          _screen(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 280));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Tide Shift has labelled directions and moving character',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await _open(tester, 'tide_shift');
    final engine = TideShiftEngine.forLevel(1);
    expect(engine.position, 30);
    expect(find.byKey(const ValueKey('tide-player')), findsOneWidget);
    expect(find.byTooltip('Move up'), findsOneWidget);
    expect(find.byTooltip('Move left'), findsOneWidget);
    expect(find.byTooltip('Move right'), findsOneWidget);
    expect(find.byTooltip('Move down'), findsOneWidget);

    await tester.tap(find.byTooltip('Move right'));
    // First draw the new location, then let the departing icon fade out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    final cell = find.byKey(const ValueKey('tide-cell-31'));
    expect(tester.widget<Semantics>(cell).properties.label,
        contains('player'));
    expect(find.byKey(const ValueKey('tide-player')), findsOneWidget);

    await tester.tap(find.byTooltip('Move down'));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.byType(Shake), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Orbit Catch animates a clockwise move and preserves controls',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await _open(tester, 'orbit_catch');
    final engine = OrbitCatchEngine.forLevel(1);
    final action = !engine.hazards.contains('0:1')
        ? 'Clockwise'
        : !engine.hazards.contains('0:11')
            ? 'Counter clockwise'
            : 'SWITCH ORBIT';
    expect(find.byKey(const ValueKey('orbit-step-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('orbit-board')), findsOneWidget);
    await tester.tap(
        action == 'SWITCH ORBIT' ? find.text(action) : find.byTooltip(action));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const ValueKey('orbit-step-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('orbit-board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tide Shift and Orbit Catch respect reduced motion',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await _open(tester, 'tide_shift', reduceMotion: true);
    final tide = find.byKey(const ValueKey('tide-cell-30'));
    final tiles = tester.widgetList<AnimatedContainer>(
      find.descendant(of: tide, matching: find.byType(AnimatedContainer)));
    expect(tiles, isNotEmpty);
    expect(tiles.first.duration, Duration.zero);
    final tideMeter = tester.widgetList<AnimatedScale>(
      find.byType(AnimatedScale));
    expect(tideMeter.any((scale) => scale.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);

    await _open(tester, 'orbit_catch', reduceMotion: true);
    final transition = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('orbit-step-0')));
    expect(transition.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
