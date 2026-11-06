import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/core/game_registry.dart';
import 'package:flooria/games/rope_untangle/rope_untangle_engine.dart';
import 'package:flooria/games/knight_tour/knight_tour_engine.dart';

const _ids = [
  'mirror_beam',
  'rope_untangle',
  'gravity_shift',
  'knight_tour',
  'rail_router',
  'tangram_fit',
];

const _sizes = [Size(360, 640), Size(390, 844)];

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String id, int level) async {
  final game = GameRegistry.byId(id);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => game.buildPage(context, GameLaunch(
        level: level,
        mode: GamePlayMode.standalone,
        onComplete: (_) {},
      )),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final id in _ids) {
    for (final size in _sizes) {
      for (final level in const [1, 90]) {
        testWidgets('$id level $level on ${size.width}x${size.height}',
            (tester) async {
          _viewport(tester, size);
          await _open(tester, id, level);
          expect(find.text('LEVEL $level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Mirror Beam rotates a mirror while the ray repaints',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'mirror_beam', 1);
    expect(find.byKey(const ValueKey('mirror-cell-22')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mirror-cell-22')));
    await tester.pump(const Duration(milliseconds: 390));
    expect(find.byType(AnimatedRotation), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rope Untangle node dragging remains interactive',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'rope_untangle', 1);
    final board = find.byKey(const ValueKey('rope-board'));
    final origin = tester.getTopLeft(board);
    final side = tester.getSize(board).width;
    final node = RopeUntangleEngine.forLevel(1).positions.first;
    await tester.dragFrom(
      origin + Offset(node.x * side, node.y * side),
      const Offset(32, -28),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gravity Shift has a movable visual orb',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'gravity_shift', 1);
    expect(find.byKey(const ValueKey('gravity-ball')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Knight moves show a destination and animate the piece',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'knight_tour', 1);
    final legal = KnightTourEngine.forLevel(1).availableMoves.first;
    await tester.tap(find.byKey(ValueKey('knight-cell-$legal')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(const ValueKey('knight-piece')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rail Router can switch the train and advance',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'rail_router', 1);
    await tester.tap(find.text('ADVANCE TRAINS'));
    await tester.pump(const Duration(milliseconds: 380));
    expect(find.byKey(const ValueKey('rail-board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tangram Fit reacts to selected shape and rotation',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await _open(tester, 'tangram_fit', 1);
    await tester.tap(find.byKey(const ValueKey('tangram-piece-0')));
    await tester.pump(const Duration(milliseconds: 210));
    await tester.tap(find.byIcon(Icons.rotate_right_rounded));
    await tester.pump(const Duration(milliseconds: 210));
    expect(find.byKey(const ValueKey('tangram-cell-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
