import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/ice_slide/ice_slide_engine.dart';
import 'package:flooria/games/magnetic_room/magnetic_room_engine.dart';
import 'package:flooria/games/number_maze/number_maze_engine.dart';
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
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final id in const ['magnetic_room', 'number_maze', 'ice_slide']) {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level at ${size.width}×${size.height}',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, id, level: level);
          expect(find.byType(GameScaffold), findsOneWidget);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Restart'));
          await tester.pump(const Duration(milliseconds: 320));
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Magnetic Room blocked pulses do not move the core',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'magnetic_room');
    final engine = MagneticRoomEngine.forLevel(1);
    expect(engine.position, 30);
    expect(engine.walls, contains(24));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('magnet-cell-30')),
    ).properties.label, contains('core'));

    await tester.tap(find.byTooltip('Pulse up'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('magnet-cell-30')),
    ).properties.label, contains('core'));

    await tester.tap(find.byTooltip('Pulse right'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('magnet-cell-31')),
    ).properties.label, contains('core'));
    expect(find.byKey(const ValueKey('magnet-board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Number Maze marks legal steps and leaves energy intact '
      'for blocked taps', (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'number_maze');
    final engine = NumberMazeEngine.forLevel(1);
    expect(engine.values[1], 2);
    final next = find.byKey(const ValueKey('maze-cell-1'));
    expect(tester.widget<Semantics>(next).properties.label,
        contains('available next step'));

    await tester.tap(next);
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.widget<Semantics>(next).properties.label,
        contains('current position'));
    expect(tester.widget<Semantics>(
      find.byKey(const ValueKey('maze-cell-2')),
    ).properties.label, contains('available next step'));

    // Far-away taps are rejected and only animate the hint.
    await tester.tap(find.byKey(const ValueKey('maze-cell-24')));
    await tester.pump(const Duration(milliseconds: 210));
    expect(tester.widget<Semantics>(next).properties.label,
        contains('current position'));
    expect(find.byType(Shake), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ice Slide preserves directional input and move counting',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'ice_slide');
    final engine = IceSlideEngine.forLevel(1);
    final direction = SlideDirection.values.firstWhere(
      (candidate) => engine.slideLength(candidate) > 0,
    );
    expect(find.byKey(const ValueKey('ice-puck')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('ice-arrow-${direction.name}')));
    await tester.pump(const Duration(milliseconds: 440));
    expect(tester.widget<Text>(
      find.byKey(const ValueKey('ice-moves')),
    ).data, '1');
    expect(find.byKey(const ValueKey('ice-puck')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new and existing motion becomes instant when reduced',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'magnetic_room', reducedMotion: true);
    final magnet = find.byKey(const ValueKey('magnet-cell-30'));
    expect(tester.widget<AnimatedContainer>(
      find.descendant(of: magnet, matching: find.byType(AnimatedContainer)),
    ).duration, Duration.zero);

    await _open(tester, 'number_maze', reducedMotion: true);
    final maze = find.byKey(const ValueKey('maze-cell-1'));
    expect(tester.widget<AnimatedScale>(
      find.descendant(of: maze, matching: find.byType(AnimatedScale)),
    ).duration, Duration.zero);

    await _open(tester, 'ice_slide', reducedMotion: true);
    expect(tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    ).duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
